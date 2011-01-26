/*
 * org.openmicroscopy.shoola.agents.imviewer.browser.ProjectionBICanvas 
 *
 *------------------------------------------------------------------------------
 *  Copyright (C) 2006-2009 University of Dundee. All rights reserved.
 *
 *
 * 	This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.shoola.agents.imviewer.browser;



//Java imports
import java.awt.Color;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.image.BufferedImage;

//Third-party libraries

//Application-internal dependencies
import org.openmicroscopy.shoola.agents.imviewer.util.ImagePaintingFactory;

/** 
 * Displays the projected image.
 *
 * @author  Jean-Marie Burel &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:j.burel@dundee.ac.uk">j.burel@dundee.ac.uk</a>
 * @author Donald MacDonald &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:donald@lifesci.dundee.ac.uk">donald@lifesci.dundee.ac.uk</a>
 * @version 3.0
 * </small>
 * @since 3.0-Beta4
 */
class ProjectionBICanvas 
	extends ImageCanvas
{

	/** The default text. */
	private static final String DEFAULT_TEXT = "Click here to preview\n" +
			" a projection of all the z-sections.";
	
    /** The mouse listener. */
    private MouseAdapter	listener;
    
    /** Reference to the UI hosting this canvas. */
    private ProjectionUI	ui;
    
    /** Does a preview of the projected image. */
    private void projectionPreview()
    {
    	//model.projectionPreview();
    	//removeMouseListener(listener);
    }
    
    /** Attaches the listener. */
    private void attachListener()
    {
    	if (listener != null) return;
    	listener = new MouseAdapter() {
			public void mouseReleased(MouseEvent e) {
				projectionPreview();
			}
		};
		addMouseListener(listener);
    }
    
    /**
     * Creates a new instance.
     *
     * @param model Reference to the Model. Mustn't be <code>null</code>.
     * @param view  Reference to the View. Mustn't be <code>null</code>.
     * @param ui  Reference to the View. Mustn't be <code>null</code>.
     */
	ProjectionBICanvas(BrowserModel model, BrowserUI view, ProjectionUI ui)
	{
		super(model, view);
		if (ui == null)
			throw new IllegalArgumentException("No UI specified.");
		this.ui = ui;
	}
	
	/**
     * Overridden to paint the image.
     * @see javax.swing.JComponent#paintComponent(Graphics)
     */
    public void paintComponent(Graphics g)
    {
        super.paintComponent(g);
        BufferedImage img = model.getDisplayedProjectedImage();
        Graphics2D g2D = (Graphics2D) g;
        ImagePaintingFactory.setGraphicRenderingSettings(g2D);
        if (img == null) {
        	img = model.getDisplayedImage();
        	if (img != null) {
        		//attachListener();
        		int w = img.getWidth()-1;
        		int h = img.getHeight()-1;
        		g2D.setColor(Color.black);
        		g2D.fillRect(0, 0, w, h);
        		FontMetrics fm = g2D.getFontMetrics();
        		g2D.setColor(Color.white);
        		//int width = fm.stringWidth(DEFAULT_TEXT);
        		//g2D.drawString(DEFAULT_TEXT, (w-width)/2, h/2);
        	}
        	return;
        }
       
        g2D.drawImage(img, null, 0, 0); 
        paintScaleBar(g2D, img.getWidth(), img.getHeight(), ui.getViewport());
        g2D.dispose();
    }
    
}