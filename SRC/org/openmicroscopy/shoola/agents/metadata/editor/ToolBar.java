/*
 * org.openmicroscopy.shoola.agents.metadata.editor.ToolBar 
 *
 *------------------------------------------------------------------------------
 *  Copyright (C) 2006-2008 University of Dundee. All rights reserved.
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
package org.openmicroscopy.shoola.agents.metadata.editor;


//Java imports
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Point;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.Iterator;
import java.util.List;
import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.Icon;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import javax.swing.JPopupMenu;
import javax.swing.JSeparator;
import javax.swing.JToolBar;


//Third-party libraries
import org.jdesktop.swingx.JXBusyLabel;

//Application-internal dependencies
import org.openmicroscopy.shoola.agents.metadata.IconManager;
import org.openmicroscopy.shoola.agents.metadata.util.ScriptMenuItem;
import org.openmicroscopy.shoola.agents.metadata.view.MetadataViewer;
import org.openmicroscopy.shoola.agents.util.EditorUtil;
import org.openmicroscopy.shoola.env.data.model.ScriptObject;
import org.openmicroscopy.shoola.util.filter.file.CppFilter;
import org.openmicroscopy.shoola.util.filter.file.CustomizedFileFilter;
import org.openmicroscopy.shoola.util.filter.file.JavaFilter;
import org.openmicroscopy.shoola.util.filter.file.MatlabFilter;
import org.openmicroscopy.shoola.util.filter.file.PythonFilter;
import org.openmicroscopy.shoola.util.ui.UIUtilities;
import pojos.ExperimenterData;
import pojos.FileAnnotationData;
import pojos.GroupData;
import pojos.ImageData;
import pojos.WellSampleData;

/** 
 * The tool bar of the editor.
 *
 * @author  Jean-Marie Burel &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:j.burel@dundee.ac.uk">j.burel@dundee.ac.uk</a>
 * @author Donald MacDonald &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:donald@lifesci.dundee.ac.uk">donald@lifesci.dundee.ac.uk</a>
 * @version 3.0
 * <small>
 * (<b>Internal version:</b> $Revision: $Date: $)
 * </small>
 * @since OME3.0
 */
class ToolBar 
	extends JPanel
{
	
	/** Button to save the annotations. */
	private JButton			saveButton;

	/** Button to download the original image. */
	private JButton			downloadButton;

	/** Button to load the rendering control for the primary select. */
	private JButton			rndButton;
	
	/** Button to refresh the selected tab. */
	private JButton			refreshButton;

	/** Button to bring up the analysis list. */
	private JButton			analysisButton;
	
	/** Button to bring up the publishing list. */
	private JButton			publishingButton;
	
	/** Button to bring up the list of scripts. */
	private JButton			scriptsButton;
	
	/** Indicates the loading progress. */
	private JXBusyLabel		busyLabel;

	/** Reference to the Control. */
	private EditorControl	controller;
	
	/** Reference to the Model. */
	private EditorModel 	model;

	/** The location of the mouse clicked. */
	private Point			location;
	
	/** The option dialog. */
	private PublishingDialog  publishingDialog;
	
	/** The option dialog. */
	private AnalysisDialog  	analysisDialog;

	/** Initializes the components. */
	private void initComponents()
	{
		setBackground(UIUtilities.BACKGROUND_COLOR);
		setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
		setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));
		IconManager icons = IconManager.getInstance();
		saveButton = new JButton(icons.getIcon(IconManager.SAVE));
		saveButton.setToolTipText("Save changes back to the server.");
		saveButton.addActionListener(controller);
		saveButton.setActionCommand(""+EditorControl.SAVE);
		saveButton.setEnabled(false);
		
		downloadButton = new JButton(icons.getIcon(IconManager.DOWNLOAD));
		downloadButton.setToolTipText("Download the Archived File(s).");
		downloadButton.addActionListener(controller);
		downloadButton.setActionCommand(""+EditorControl.DOWNLOAD);
		downloadButton.setEnabled(false);
		
		rndButton = new JButton(icons.getIcon(IconManager.RENDERER));
		rndButton.setToolTipText("Rendering control for the primary selected " +
				"image.");
		rndButton.addActionListener(controller);
		rndButton.setActionCommand(""+EditorControl.RENDERER);
		rndButton.setEnabled(false);
		
		refreshButton = new JButton(icons.getIcon(IconManager.REFRESH));
		refreshButton.setToolTipText("Refresh the selected tab.");
		refreshButton.addActionListener(controller);
		refreshButton.setActionCommand(""+EditorControl.REFRESH);
		
		publishingButton = new JButton(icons.getIcon(IconManager.PUBLISHING));
		publishingButton.setToolTipText("Display the publishing options.");
		publishingButton.setEnabled(false);
		publishingButton.addMouseListener(new MouseAdapter() {
			
			/**
			 * Launches the dialog when the user releases the mouse.
			 * MouseAdapter#mouseReleased(MouseEvent)
			 */
			public void mouseReleased(MouseEvent e)
			{
				launchOptions((Component) e.getSource(), e.getPoint(), 
						MetadataViewer.PUBLISHING_OPTION);
			}
		});
		analysisButton = new JButton(icons.getIcon(IconManager.ANALYSIS));
		analysisButton.setToolTipText("Display the analysis options.");
		analysisButton.setEnabled(false);
		analysisButton.addMouseListener(new MouseAdapter() {
			
			/**
			 * Launches the dialog when the user releases the mouse.
			 * MouseAdapter#mouseReleased(MouseEvent)
			 */
			public void mouseReleased(MouseEvent e)
			{
				launchOptions((Component) e.getSource(), e.getPoint(), 
						MetadataViewer.ANALYSIS_OPTION);
			}
		});
		scriptsButton = new JButton(icons.getIcon(IconManager.ANALYSIS));
		scriptsButton.setToolTipText("Display the available scripts.");
		scriptsButton.setEnabled(false);
		scriptsButton.addMouseListener(new MouseAdapter() {
			
			/**
			 * Loads the scripts of displays them if already loaded.
			 * MouseAdapter#mousePressed(MouseEvent)
			 */
			public void mouseReleased(MouseEvent e)
			{
				if (model.getScripts() == null) {
					location = e.getPoint();
					scriptsButton.setEnabled(false);
					model.loadScripts();
					setStatus(true);
				} else {
					launchOptions((Component) e.getSource(), e.getPoint(), 
						MetadataViewer.SCRIPTS_OPTION);
				}
			}
		});
		refreshButton.addActionListener(controller);
		refreshButton.setActionCommand(""+EditorControl.REFRESH);
		UIUtilities.unifiedButtonLookAndFeel(saveButton);
		UIUtilities.unifiedButtonLookAndFeel(downloadButton);
		UIUtilities.unifiedButtonLookAndFeel(rndButton);
		UIUtilities.unifiedButtonLookAndFeel(refreshButton);

		UIUtilities.unifiedButtonLookAndFeel(publishingButton);
		UIUtilities.unifiedButtonLookAndFeel(analysisButton);
		UIUtilities.unifiedButtonLookAndFeel(scriptsButton);
		Dimension d = new Dimension(UIUtilities.DEFAULT_ICON_WIDTH, 
				UIUtilities.DEFAULT_ICON_HEIGHT);
    	busyLabel = new JXBusyLabel(d);
    	busyLabel.setEnabled(true);
    	busyLabel.setVisible(false);
	}
	
    /** 
     * Builds the general bar.
     * 
     * @return See above.
     */
    private JComponent buildGeneralBar()
    {
    	JToolBar bar = new JToolBar();
    	bar.setBackground(UIUtilities.BACKGROUND_COLOR);
    	bar.setFloatable(false);
    	bar.setRollover(true);
    	bar.setBorder(null);
    	bar.add(saveButton);
    	bar.add(Box.createHorizontalStrut(5));
    	bar.add(refreshButton);
    	bar.add(Box.createHorizontalStrut(5));
    	bar.add(downloadButton);
    	bar.add(Box.createHorizontalStrut(5));
    	bar.add(publishingButton);
    	bar.add(Box.createHorizontalStrut(5));
    	bar.add(analysisButton);
    	bar.add(Box.createHorizontalStrut(5));
    	bar.add(scriptsButton);
    	return bar;
    }
    
    /** Builds and lays out the UI. */
    private void buildGUI()
    {
    	JPanel bars = new JPanel();
    	bars.setBackground(UIUtilities.BACKGROUND_COLOR);
    	bars.setLayout(new BoxLayout(bars, BoxLayout.X_AXIS));
    	bars.add(buildGeneralBar());
    	JPanel p = new JPanel();
    	p.setBackground(UIUtilities.BACKGROUND_COLOR);
    	p.setLayout(new BoxLayout(p, BoxLayout.X_AXIS));
    	JPanel pp = UIUtilities.buildComponentPanel(bars);
    	pp.setBackground(UIUtilities.BACKGROUND_COLOR);
    	p.add(pp);
    	pp = UIUtilities.buildComponentPanelRight(busyLabel);
    	pp.setBackground(UIUtilities.BACKGROUND_COLOR);
    	p.add(pp);
    	setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    	add(p);
    	add(new JSeparator());
    }
    
    /**
     * Sets the icon associated to the script.
     * 
     * @param so The script to handle.
     */
    private void setScriptIcon(ScriptObject so)
    {
    	if (so.getIcon() != null) return;
    	Icon icon = null, largeIcon = null;
    	Iterator<CustomizedFileFilter> i = EditorUtil.SCRIPTS_FILTERS.iterator();
    	CustomizedFileFilter filter;
    	IconManager icons = IconManager.getInstance();
    	while (i.hasNext()) {
    		filter = i.next();
			if (filter.accept(so.getName())) {
				if (filter instanceof CppFilter) {
					largeIcon = icons.getIcon(IconManager.CPP_48);
					icon = icons.getIcon(IconManager.CPP);
				} else if (filter instanceof MatlabFilter) {
					icon = icons.getIcon(IconManager.MATLAB);
					largeIcon = icons.getIcon(IconManager.MATLAB_48);
				} else if (filter instanceof JavaFilter) {
					icon = icons.getIcon(IconManager.JAVA);
					largeIcon = icons.getIcon(IconManager.JAVA_48);
				} else if (filter instanceof PythonFilter) {
					icon = icons.getIcon(IconManager.PYTHON);
					largeIcon = icons.getIcon(IconManager.PYTHON_48);
				}
				break;
			}
		}
    	if (icon == null)
    		icon = icons.getIcon(IconManager.ANALYSIS);
    	if (largeIcon == null)
    		largeIcon = icons.getIcon(IconManager.ANALYSIS_48);
    	so.setIcon(icon);
    	so.setIconLarge(largeIcon);
    }
    
    /** 
     * Builds the menu displaying the available scripts.
     * 
     * @return See above.
     */
    private JPopupMenu getScriptsMenu()
    {
    	JPopupMenu menu = new JPopupMenu();
    	List scripts = model.getScripts();
    	if (scripts == null) return menu;
    	Iterator i = scripts.iterator();
    	ScriptObject so;
    	JMenuItem item;
    	while (i.hasNext()) {
    		so = (ScriptObject) i.next();
    		setScriptIcon(so);
    		item = new ScriptMenuItem(so);
    		item.addActionListener(controller);
			menu.add(item);
		}
    	return menu;
    }
    
    /**
     * Creates a new instance.
     * 
     * @param model 		Reference to the model. 
     * 						Mustn't be <code>null</code>.
     * @param controller 	Reference to the view. Mustn't be <code>null</code>.
     */
    ToolBar(EditorModel model, EditorControl controller)
    {
    	if (model == null)
    		throw new IllegalArgumentException("No model.");
    	if (controller == null)
    		throw new IllegalArgumentException("No control.");
    	this.model = model;
    	this.controller = controller;
    	initComponents();
    	buildGUI();
    }
    
    /** Enables the various controls. */
    void setControls()
    { 
    	if (model.getRefObject() instanceof FileAnnotationData) {
    		downloadButton.setEnabled(true); 
    	} else 
    		downloadButton.setEnabled(model.isArchived()); 
    }
    
    /**
     * Enables the {@link #saveButton} depending on the passed value.
     * 
     * @param b Pass <code>true</code> to save the data,
     * 			<code>false</code> otherwise. 
     */
    void setDataToSave(boolean b) { saveButton.setEnabled(b); }
    
    /**
     * Sets to <code>true</code> if loading data, to <code>false</code>
     * otherwise.
     * 
     * @param busy 	Pass <code>true</code> while loading data, 
     * 				<code>false</code> otherwise.
     */
    void setStatus(boolean busy)
    {
    	busyLabel.setBusy(busy);
    	busyLabel.setVisible(busy);
    }
    
    /** Updates the UI when a new object is selected. */
    void buildUI()
    {
    	Object refObject = model.getRefObject();
    	rndButton.setEnabled(false);
		downloadButton.setEnabled(false);
    	if ((refObject instanceof ImageData) || 
    			(refObject instanceof WellSampleData)) {
    		rndButton.setEnabled(!model.isRendererLoaded());
    		if (model.isNumerousChannel())
    			rndButton.setEnabled(false);
    		if (refObject instanceof ImageData) {
    			downloadButton.setEnabled(model.isArchived());
    		}
    			
    	} else if (refObject instanceof FileAnnotationData) {
    		downloadButton.setEnabled(true);
    	}
    	revalidate();
    	repaint();
    }

    /** Sets the root object. */
	void setRootObject()
	{ 
		Object ref = model.getRefObject();
		if ((ref instanceof ExperimenterData) || 
			(ref instanceof GroupData)) {
			publishingButton.setEnabled(false);
			analysisButton.setEnabled(false);
			scriptsButton.setEnabled(false);
			return;
		}
		publishingButton.setEnabled(true);
		analysisButton.setEnabled(true);
		scriptsButton.setEnabled(true);
		if (publishingDialog != null) publishingDialog.setRootObject();
		if (analysisDialog != null) analysisDialog.setRootObject();
	}

	/**
	 * Launches the Options.
	 * 
	 * @param source The location of the mouse pressed.
	 * @param p 	 The location of the mouse pressed.
	 * @param index  Identifies the menu to pop up.
	 */
	void launchOptions(Component source, Point p, int index)
	{
		if (p == null) p = new Point(0, 0);
		switch (index) {
			case MetadataViewer.PUBLISHING_OPTION:
				if (publishingDialog == null)
					publishingDialog = new PublishingDialog(controller, model);
				publishingDialog.displayAsMenu().show(source, p.x, p.y);
				break;

			case MetadataViewer.ANALYSIS_OPTION:
				if (analysisDialog == null)
					analysisDialog = new AnalysisDialog(controller, model);
				analysisDialog.displayAsMenu().show(source, p.x, p.y);
				break;
			case MetadataViewer.SCRIPTS_OPTION:
				getScriptsMenu().show(source, p.x, p.y);
		}
	}
	
	/** Sets the scripts. */
	void setScripts()
	{
		scriptsButton.setEnabled(true);
		setStatus(false);
		launchOptions(scriptsButton, location, MetadataViewer.SCRIPTS_OPTION);
		location = null;
	}
	
}
	