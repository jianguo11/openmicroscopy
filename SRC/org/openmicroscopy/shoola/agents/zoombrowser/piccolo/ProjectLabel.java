/*
 * org.openmicroscopy.shoola.agents.zoombrowser.piccolo.ProjectLabel
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */

/*------------------------------------------------------------------------------
*
* Written by:    Harry Hochheiser <hsh@nih.gov>
*
*------------------------------------------------------------------------------
*/

package org.openmicroscopy.shoola.agents.zoombrowser.piccolo;


//java imports
import java.awt.Paint;

//Third-party libraries
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;

//Application-internal dependencies
import org.openmicroscopy.shoola.agents.zoombrowser.data.BrowserProjectSummary;
import org.openmicroscopy.shoola.agents.zoombrowser.SelectionState;

/** 
 * Project labels, as found on a {@link ProjctSelectionCanvas}
 *
 * @author  Harry Hochheiser &nbsp;&nbsp;&nbsp;&nbsp;
 * 				<a href="mailto:hsh@nih.gov">hsh@nih.gov</a>
 *
 * @version 2.2
 * <small>
 * (<b>Internal version:</b> $Revision$ $Date$)
 * </small>
 */

public class ProjectLabel extends PText implements MouseableNode {
	
	public static final double NORMAL_SCALE=1;	
		public static final double ROLLOVER_SCALE=1.25;
	public static final double SELECTED_SCALE=1.5;
	public BrowserProjectSummary project;
	
	private double previousScale =NORMAL_SCALE;
	private Paint previousPaint;
	ProjectSelectionCanvas canvas;
	
	
	
	ProjectLabel(BrowserProjectSummary project,ProjectSelectionCanvas canvas) {
		super();
		this.project = project;
		this.canvas = canvas;
		setText(project.getName());
		setFont(PConstants.PROJECT_LABEL_FONT);
		
	}
	
	public double getScaledMaxWidth() {
		PBounds b = getGlobalFullBounds();
		return b.getWidth()*SELECTED_SCALE/getScale();
	}

	public double getScaledMaxHeight() {
		PBounds b = getGlobalFullBounds();
		return b.getHeight()*SELECTED_SCALE/getScale();
	}
	
	
	public BrowserProjectSummary getProject() {
		return project;
	}
	
	
	public void setNormal() {
		if (project == SelectionState.getState().getSelectedProject())
			return; 
		setScale(NORMAL_SCALE);
		setPaint(PConstants.DEFAULT_COLOR);
	}
	
	public void setActive() {
		if (project == SelectionState.getState().getSelectedProject())
					return; 
		setScale(NORMAL_SCALE);
		setPaint(PConstants.PROJECT_ACTIVE_COLOR);
	}
	
	public void setSelected() {
		setScale(SELECTED_SCALE);
		setPaint(PConstants.PROJECT_SELECTED_COLOR);
		
	}
	
	public void setRollover(boolean v) {
		if (project == SelectionState.getState().getSelectedProject())
			return;
		if (v == true) {
			setScale(ROLLOVER_SCALE);
			setPaint(PConstants.PROJECT_ROLLOVER_COLOR);
		}
		else  {
			setNormal();
		}
	}
	
	public void mouseEntered(GenericEventHandler handler) {
		BrowserProjectSummary p = getProject();
		if (p.hasDatasets())
			SelectionState.getState().setRolloverProject(p); 
	}

	public void mouseExited(GenericEventHandler handler) {
		SelectionState.getState().setRolloverProject(null);
	}

	public void mouseClicked(GenericEventHandler handler) {
		BrowserProjectSummary project = getProject();
		SelectionState state = SelectionState.getState();

		BrowserProjectSummary selected = state.getSelectedProject();
		if (selected == project) { 
			// if i've just clicked on what was selected,
			// clear dataset selection
			state.setSelectedDataset(null);
	
		}
		else if (project.hasDatasets())
			state.setSelectedProject(project);
	}

	public void mousePopup(GenericEventHandler handler) {
		BrowserProjectSummary picked = getProject();
		BrowserProjectSummary selected = 
			SelectionState.getState().getSelectedProject();
		if (picked == selected) 
			SelectionState.getState().setSelectedProject(null);	
	}

	public void mouseDoubleClicked(GenericEventHandler handler) {
		SelectionState state = SelectionState.getState();
		if (state.getSelectedProject() != null) {
			state.setSelectedProject(null);
		}
	}
	
}