--
-- Copyright 2010 Glencoe Software, Inc. All rights reserved.
-- Use is subject to license terms supplied in LICENSE.txt
--

--
-- This SQL script produces a report of permission issues in
-- OMERO4.1__0 databases. See ticket #2204 for more information.
--

--
-- Helper methods
--

create or replace function omero_empty_if_null(txt text)
    returns text as '
begin
        if txt is null then
            return substr(''empty'', 0, 1);
        else
            return txt;
        end if;

end;' language 'plpgsql' immutable;

create or replace function omero_unnest(anyarray)
  returns setof anyelement AS '
    select $1[I] from
        generate_series(array_lower($1,1),
                        array_upper($1,1)) i;
' language 'sql' immutable;

drop aggregate if exists omero_textcat_all(text);

create aggregate omero_textcat_all(
  basetype    = text,
  sfunc       = textcat,
  stype       = text,
  initcond    = ''
);


--
-- Check methods
--

create or replace function omero_41_check(target varchar, tbl varchar, col varchar, ACTION text) returns setof text as '
declare
    sql varchar;
    txt text;
begin

    sql := ''select target.id as target_id, target.group_id as target_group, target.owner_id as target_owner, ome_perms(target.permissions) as target_perms, '' ||
        ''          tbl.id as tbl_id,       tbl.group_id as tbl_group,       tbl.owner_id as tbl_owner,    ome_perms(tbl.permissions) as tbl_perms '' ||
        ''from '' || target || '' target, '' || tbl || '' tbl '' ||
        ''where target.id = tbl.''|| col || -- Base query linking the two tables
                '' and ( target.group_id <> tbl.group_id '' || -- groups do not match
                ''   or target.owner_id not in (select child from groupexperimentermap where parent = tbl.group_id) '' || -- target owner not in tbl group
                ''   or tbl.owner_id not in (select child from groupexperimentermap where parent = target.group_id)) ''; -- tbl owner not in target group

    for txt in select omero_41_check(sql, target, tbl, col, ACTION) loop
        return next txt;
    end loop;

    return;

end;' language plpgsql;

create or replace function omero_41_check(sql varchar, target varchar, tbl varchar, col varchar, ACTION text) returns setof text as $$
declare
    rec record;
    txt text;
    mod text;
begin

    for rec in execute sql loop

        txt := 'Warning';
        txt := txt || ': ' || target || '(';
        txt := txt || 'id='    || rec.target_id || ', ';
        txt := txt || 'group=' || rec.target_group || ', ';
        txt := txt || 'owner=' || rec.target_owner || ', ';
        txt := txt || 'perms=' || rec.target_perms || ')';
        txt := txt || ' <--> ' || tbl || '.';
        txt := txt || col || '(';
        txt := txt || 'id='    || rec.tbl_id || ', ';
        txt := txt || 'group=' || rec.tbl_group || ', ';
        txt := txt || 'owner=' || rec.tbl_owner || ', ';
        txt := txt || 'perms=' || rec.tbl_perms || ')';

        if ACTION = 'DELETE' then

            mod := 'delete from ' || tbl || ' where id = '|| rec.tbl_id || ' returning ''Check:deleted '|| tbl ||'(id='||rec.tbl_id||')'' ';
            for txt in execute mod loop
                return next txt;
            end loop;

        elsif ACTION = 'FIX' then

            mod := 'update ' || tbl || ' set group_id = ' || rec.target_group ||' where id = '|| rec.tbl_id || ' returning ''Check:changed group '|| tbl ||'(id='||rec.tbl_id||')'' ';
            for txt in execute mod loop
                return next txt;
            end loop;

        else

            return next txt;

        end if;
    end loop;

    return;

end;$$ language plpgsql;


create or replace function omero_41_perms(tbl text, ACTION text) returns setof text as $$
declare
    rec record;
    sql text;
    mod text;
    txt text;
    fmt int8;
begin

    -- Skipped because system types in 4.2 (includes enums)
    if tbl in ('experimenter', 'experimentergroup', 'groupexperimentermap', 'sharemember', 'eventtype',
        'immersion', 'arctype',  'renderingmodel',  'acquisitionmode',
        'binning',  'family',  'medium',  'pixelstype',  'format',  'pulse',
        'lasertype',  'jobstatus',  'detectortype',  'microbeammanipulationtype',
        'illumination',  'photometricinterpretation',  'correction',  'eventtype',
        'lasermedium',  'microscopetype',  'dimensionorder',  'experimenttype',
        'contrastmethod',  'filamenttype',  'filtertype') then

        return;
    end if;

    sql := 'select id, group_id, owner_id, ome_perms(permissions) from ' || tbl || ' where ' ||
        '(cast(permissions as bit(64)) & cast(   4 as bit(64))) = cast(   4 as bit(64))';

    begin

        if tbl = 'originalfile' then
            select into fmt id from format where value = 'Directory';
        end if;

        for rec in execute sql loop

            if tbl = 'originalfile' then
                if rec.group_id = 0 and
                    (
                        name in ('makemovie.py', 'populateroi.py')
                        or
                        format = fmt
                    ) then
                    continue;
                end if;
            end if;

            if ACTION = 'DELETE' then

                mod := 'delete from ' || tbl || ' where id = '|| rec.id || ' returning ''Permissions:deleted '' '|| tbl ||' ''(id='' ||  id::text || '')'' ';
                for txt in execute mod loop
                    return next txt;
                end loop;

            elsif ACTION = 'FIX' then

                mod := 'update ' || tbl || ' set permissions = g.permissions from experimenter group g where g.id = group_id and id = '|| rec.id || ' returning ''Permissions:modified '' '|| tbl ||' ''(id='' ||  id::text || '')'' ';
                for txt in execute mod loop
                    return next txt;
                end loop;
            else

                return next 'Non-private permissions:' || tbl || '(id=' || rec.id || ')' || chr(10);

            end if;
        end loop;
    exception when others then
        -- do nothing
    end;

    return;

end;$$ language plpgsql;


-- General information for parsing the rest.
select * from dbpatch;
select * from experimentergroup;
select * from groupexperimentermap;
-- Not displaying experimenter to protect emails, etc.

create or replace function omero_41_lockchecks() returns setof record stable strict as '
declare
    rec record;
begin
    for rec in select ''Dataset''::text, ''DatasetImageLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Dataset''::text, ''ProjectDatasetLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Dataset''::text, ''DatasetAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Plate''::text, ''Well''::text, ''plate''::text loop return next rec; end loop;
    for rec in select ''Plate''::text, ''PlateAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Plate''::text, ''ScreenPlateLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Channel''::text, ''ChannelAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Microscope''::text, ''Instrument''::text, ''microscope''::text loop return next rec; end loop;
    for rec in select ''WellSample''::text, ''WellSampleAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''WellSample''::text, ''ScreenAcquisitionWellSampleLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''PlaneInfo''::text, ''PlaneInfoAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''TransmittanceRange''::text, ''Filter''::text, ''transmittanceRange''::text loop return next rec; end loop;
    for rec in select ''QuantumDef''::text, ''RenderingDef''::text, ''quantization''::text loop return next rec; end loop;
    for rec in select ''Image''::text, ''ImageAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Image''::text, ''WellSample''::text, ''image''::text loop return next rec; end loop;
    for rec in select ''Image''::text, ''DatasetImageLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Image''::text, ''Pixels''::text, ''image''::text loop return next rec; end loop;
    for rec in select ''Image''::text, ''Roi''::text, ''image''::text loop return next rec; end loop;
    for rec in select ''MicrobeamManipulation''::text, ''LightSettings''::text, ''microbeamManipulation''::text loop return next rec; end loop;
    for rec in select ''RenderingDef''::text, ''CodomainMapContext''::text, ''renderingDef''::text loop return next rec; end loop;
    for rec in select ''RenderingDef''::text, ''ChannelBinding''::text, ''renderingDef''::text loop return next rec; end loop;
    for rec in select ''Project''::text, ''ProjectAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Project''::text, ''ProjectDatasetLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''StageLabel''::text, ''Image''::text, ''stageLabel''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''Channel''::text, ''pixels''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''PlaneInfo''::text, ''pixels''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''Pixels''::text, ''relatedTo''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''Shape''::text, ''pixels''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''PixelsAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Pixels''::text, ''PixelsOriginalFileMap''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Roi''::text, ''RoiAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Roi''::text, ''Shape''::text, ''roi''::text loop return next rec; end loop;
    for rec in select ''ObjectiveSettings''::text, ''Image''::text, ''objectiveSettings''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''Image''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''Detector''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''OTF''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''FilterSet''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''LightSource''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''Dichroic''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''Objective''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''Instrument''::text, ''Filter''::text, ''instrument''::text loop return next rec; end loop;
    for rec in select ''ScreenAcquisition''::text, ''ScreenAcquisitionAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''ScreenAcquisition''::text, ''ScreenAcquisitionWellSampleLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Well''::text, ''WellAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Well''::text, ''WellSample''::text, ''well''::text loop return next rec; end loop;
    for rec in select ''Well''::text, ''WellReagentLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''ImagingEnvironment''::text, ''Image''::text, ''imagingEnvironment''::text loop return next rec; end loop;
    for rec in select ''Reagent''::text, ''WellReagentLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Reagent''::text, ''ReagentAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Detector''::text, ''DetectorSettings''::text, ''detector''::text loop return next rec; end loop;
    for rec in select ''OTF''::text, ''LogicalChannel''::text, ''otf''::text loop return next rec; end loop;
    for rec in select ''LightSettings''::text, ''LogicalChannel''::text, ''lightSourceSettings''::text loop return next rec; end loop;
    for rec in select ''LightSource''::text, ''LightSettings''::text, ''lightSource''::text loop return next rec; end loop;
    for rec in select ''OriginalFile''::text, ''OriginalFileAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''OriginalFile''::text, ''JobOriginalFileLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''OriginalFile''::text, ''Roi''::text, ''source''::text loop return next rec; end loop;
    for rec in select ''OriginalFile''::text, ''PixelsOriginalFileMap''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Job''::text, ''JobOriginalFileLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''WellSampleAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''WellAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ImageAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''OriginalFileAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''PlaneInfoAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ChannelAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ExperimenterGroupAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''RoiAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''AnnotationAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''AnnotationAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''NodeAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ProjectAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ReagentAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''PlateAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ExperimenterAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ScreenAcquisitionAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''ScreenAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''PixelsAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''DatasetAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''Annotation''::text, ''SessionAnnotationLink''::text, ''child''::text loop return next rec; end loop;
    for rec in select ''FilterSet''::text, ''OTF''::text, ''filterSet''::text loop return next rec; end loop;
    for rec in select ''FilterSet''::text, ''LogicalChannel''::text, ''filterSet''::text loop return next rec; end loop;
    for rec in select ''StatsInfo''::text, ''Channel''::text, ''statsInfo''::text loop return next rec; end loop;
    for rec in select ''Screen''::text, ''ScreenAcquisition''::text, ''screen''::text loop return next rec; end loop;
    for rec in select ''Screen''::text, ''Reagent''::text, ''screen''::text loop return next rec; end loop;
    for rec in select ''Screen''::text, ''ScreenAnnotationLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Screen''::text, ''ScreenPlateLink''::text, ''parent''::text loop return next rec; end loop;
    for rec in select ''Dichroic''::text, ''FilterSet''::text, ''dichroic''::text loop return next rec; end loop;
    for rec in select ''Objective''::text, ''ObjectiveSettings''::text, ''objective''::text loop return next rec; end loop;
    for rec in select ''Objective''::text, ''OTF''::text, ''objective''::text loop return next rec; end loop;
    for rec in select ''Experiment''::text, ''Image''::text, ''experiment''::text loop return next rec; end loop;
    for rec in select ''Experiment''::text, ''MicrobeamManipulation''::text, ''experiment''::text loop return next rec; end loop;
    for rec in select ''DetectorSettings''::text, ''LogicalChannel''::text,''detectorSettings''::text loop return next rec; end loop;
    for rec in select ''Filter''::text, ''FilterSet''::text, ''emFilter''::text loop return next rec; end loop;
    for rec in select ''Filter''::text, ''FilterSet''::text, ''exFilter''::text loop return next rec; end loop;
    for rec in select ''Filter''::text, ''LogicalChannel''::text, ''secondaryEmissionFilter''::text loop return next rec; end loop;
    for rec in select ''Filter''::text, ''LogicalChannel''::text, ''secondaryExcitationFilter''::text loop return next rec; end loop;
    for rec in select ''LogicalChannel''::text, ''Channel''::text, ''logicalChannel''::text loop return next rec; end loop;
    for rec in select ''Shape''::text, ''LogicalChannel''::text, ''shapes''::text loop return next rec; end loop;
    -- Disabled since deleted by upgrade script
    -- for rec in select ''Pixels''::text, ''Thumbnail''::text, ''pixels''::text loop return next rec; end loop;
    -- for rec in select ''Pixels''::text, ''RenderingDef''::text, ''pixels''::text loop return next rec; end loop;
    return;
end;' language plpgsql;


create or replace function omero_41_check(ACTION text) returns setof text as $$
declare
    sum text = '';
    txt text;
begin

    for txt in select omero_41_check(target, tbl, col, ACTION) from omero_41_lockchecks() as (target text, tbl text, col text) loop
        sum := sum || txt || chr(10);
        return next txt;
    end loop;

    -- The following are irregular and so must be custom written.

    for txt in select omero_41_check(
        'select target.id as target_id, target.group_id as target_group, target.owner_id as target_owner, ome_perms(target.permissions) as target_perms, ' ||
        '          tbl.id as tbl_id,       tbl.group_id as tbl_group,       tbl.owner_id as tbl_owner,    ome_perms(tbl.permissions) as tbl_perms ' ||
        '  from lightsource target, lightsource tbl, laser tbl2 ' ||
        ' where target.id = tbl2.pump and tbl2.lightsource_id = tbl.id ' ||
        '   and target.group_id <> tbl.group_id;',
        'LightSource', 'Laser', 'pump', ACTION) loop
        sum := sum || txt || chr(10);
        return next txt;
    end loop;

    for txt in select omero_41_check(
        'select target.id as target_id, target.group_id as target_group, target.owner_id as target_owner, ome_perms(target.permissions) as target_perms, ' ||
        '          tbl.id as tbl_id,       tbl.group_id as tbl_group,       tbl.owner_id as tbl_owner,    ome_perms(tbl.permissions) as tbl_perms ' ||
        '  from originalfile target, annotation tbl ' ||
        ' where target.id = tbl.file ' ||
        '   and target.group_id <> tbl.group_id;',
        'OriginalFile', 'FileAnnotation','file', ACTION) loop
        sum := sum || txt || chr(10);
        return next txt;
    end loop;

    for txt in select omero_41_check(
        'select target.id as target_id, target.group_id as target_group, target.owner_id as target_owner, ome_perms(target.permissions) as target_perms, ' ||
        '          tbl.id as tbl_id,       tbl.group_id as tbl_group,       tbl.owner_id as tbl_owner,    ome_perms(tbl.permissions) as tbl_perms ' ||
        '  from thumbnail target, annotation tbl ' ||
        ' where target.id = tbl.thumbnail ' ||
        '   and target.group_id <> tbl.group_id;',
        'Thumbnail', 'ThumbnailAnnotation','thumbnail', ACTION) loop
        sum := sum || txt || chr(10);
        return next txt;
    end loop;

    -- The following are disabled since they are system types in 4.2
    -- select omero_41_check('ExperimenterGroup', 'GroupExperimenterMap','parent');
    -- select omero_41_check('ExperimenterGroup', 'ExperimenterGroupAnnotationLink','parent');

    for txt in select omero_41_perms(tables, ACTION) as "Permissions" from omero_unnest(string_to_array(
        'acquisitionmode annotation annotationannotationlink arc arctype binning channel ' ||
        'channelannotationlink channelbinding codomainmapcontext contrastmethod ' ||
        'contraststretchingcontext correction dataset datasetannotationlink ' ||
        'datasetimagelink dbpatch detector detectorsettings detectortype dichroic ' ||
        'dimensionorder event eventlog eventtype experiment experimenter ' ||
        'experimenterannotationlink experimentergroup experimentergroupannotationlink ' ||
        'experimenttype externalinfo family filament filamenttype filter filterset ' ||
        'filtertype format groupexperimentermap illumination image imageannotationlink ' ||
        'imagingenvironment immersion importjob instrument job joboriginalfilelink ' ||
        'jobstatus laser lasermedium lasertype lightemittingdiode lightsettings ' ||
        'lightsource link logicalchannel medium microbeammanipulation ' ||
        'microbeammanipulationtype microscope microscopetype node nodeannotationlink ' ||
        'objective objectivesettings originalfile originalfileannotationlink otf ' ||
        'photometricinterpretation pixels pixelsannotationlink pixelsoriginalfilemap ' ||
        'pixelstype planeinfo planeinfoannotationlink planeslicingcontext plate ' ||
        'plateannotationlink project projectannotationlink projectdatasetlink pulse ' ||
        'quantumdef reagent reagentannotationlink renderingdef renderingmodel ' ||
        'reverseintensitycontext roi roiannotationlink screen screenacquisition ' ||
        'screenacquisitionannotationlink screenacquisitionwellsamplelink ' ||
        'screenannotationlink screenplatelink scriptjob session sessionannotationlink ' ||
        'shape share sharemember stagelabel statsinfo thumbnail transmittancerange well ' ||
        'wellannotationlink wellreagentlink wellsample wellsampleannotationlink', ' ')) as tables loop
        sum := sum || txt || chr(10);
        return next txt;
    end loop;

    if ACTION = 'ABORT' and char_length(sum) > 0 then
        txt := chr(10) || sum || chr(10);
        txt := txt || 'ERROR ON omero_41_check:' || chr(10);
        txt := txt || 'Your database has data which is incompatible with 4.2 and will need to be manually updated' || chr(10);
        txt := txt || 'Contact ome-users@openmicroscopy.org.uk for help adjusting your data.' || chr(10) || chr(10);
        raise exception '%', txt;
    end if;

    return;

end;$$ language plpgsql;


-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

select omero_41_check(:ACTION);

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


drop function omero_41_check(text);
drop function omero_41_perms(text, text);
drop function omero_41_check(varchar, varchar, varchar, text);
drop function omero_41_check(varchar, varchar, varchar, varchar, text);
drop function omero_unnest(anyarray);
drop function omero_41_lockchecks();
drop function omero_empty_if_null(text);