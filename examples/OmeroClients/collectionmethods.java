import omero.model.Dataset;
import omero.model.DatasetI;
import omero.model.DatasetImageLink;
import omero.model.DatasetImageLinkI;
import omero.model.EventI;
import omero.model.Image;
import omero.model.ImageI;
import omero.model.Pixels;
import omero.model.PixelsI;

import java.util.*;

public class collectionmethods {

    public static void main(String args[]) {

        Image image = new ImageI(1, true);
        image.getDetails().setUpdateEvent( new EventI(1L, false) );

        // On creation, all collections are
        // initialized to empty, and can be added
        // to.
        assert image.sizeOfDatasetLinks() == 0;
        Dataset dataset = new DatasetI(1L, false);
        DatasetImageLink link = image.linkDataset(dataset);
        assert image.sizeOfDatasetLinks() == 1;

        // If you want to work with this collection,
        // you'll need to get a copy.
        List<DatasetImageLink> links = image.copyDatasetLinks();

        // When you are done working with it, you can
        // unload the datasets, assuming the changes
        // have been persisted to the server.
        image.unloadDatasetLinks();
        assert image.sizeOfDatasetLinks() < 0;
        try {
            image.linkDataset( new DatasetI() );
        } catch (Exception e) {
            // Can't access an unloaded collection
        }

        // The reload...() method allows one instance
        // to take over a collection from another, if it
        // has been properly initialized on the server.
        // sameImage will have it's collection unloaded.
        Image sameImage = new ImageI(1L, true);
        sameImage.getDetails().setUpdateEvent( new EventI(1L, false) );
        sameImage.linkDataset( new DatasetI(1L, false) );
        image.reloadDatasetLinks( sameImage );
        assert image.sizeOfDatasetLinks() == 1;
        assert sameImage.sizeOfDatasetLinks() < 0;

        // If you would like to remove all the member
        // elements from a collection, don't unload it
        // but "clear" it.
        image.clearDatasetLinks();
        // Saving this to the database will remove
        // all dataset links!

        // Finally, all collections can be unloaded
        // to use an instance as a single row in the db.
        image.unloadCollections();

        // Ordered collections have slightly different methods.
        image = new ImageI(1L, true);
        image.addPixels( new PixelsI() );
        image.getPixels(0);
        image.getPrimaryPixels(); // Same thing
        image.removePixels( image.getPixels(0) );

   }

}
