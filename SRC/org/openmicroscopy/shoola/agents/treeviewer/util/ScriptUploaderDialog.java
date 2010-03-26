/*
 * org.openmicroscopy.shoola.agents.treeviewer.util.ScriptUploaderDialog
 *
 *------------------------------------------------------------------------------
 *  Copyright (C) 2006-2010 University of Dundee. All rights reserved.
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
package org.openmicroscopy.shoola.agents.treeviewer.util;


//Java imports
import java.awt.BorderLayout;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.swing.Box;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JRootPane;
import javax.swing.JTextField;
import javax.swing.UIManager;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;

//Third-party libraries
import info.clearthought.layout.TableLayout;

//Application-internal dependencies
import org.jdesktop.swingx.JXTaskPane;
import org.openmicroscopy.shoola.agents.treeviewer.IconManager;
import org.openmicroscopy.shoola.agents.treeviewer.TreeViewerAgent;
import org.openmicroscopy.shoola.env.data.model.ScriptObject;
import org.openmicroscopy.shoola.env.ui.UserNotifier;
import org.openmicroscopy.shoola.util.filter.file.CppFilter;
import org.openmicroscopy.shoola.util.filter.file.CustomizedFileFilter;
import org.openmicroscopy.shoola.util.filter.file.JavaFilter;
import org.openmicroscopy.shoola.util.filter.file.MatlabFilter;
import org.openmicroscopy.shoola.util.filter.file.PythonFilter;
import org.openmicroscopy.shoola.util.ui.MessageBox;
import org.openmicroscopy.shoola.util.ui.TitlePanel;
import org.openmicroscopy.shoola.util.ui.UIUtilities;

import pojos.ExperimenterData;


/** 
 * Dialog used to select the scripts to upload to the server.
 *
 * @author  Jean-Marie Burel &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:j.burel@dundee.ac.uk">j.burel@dundee.ac.uk</a>
 * @author Donald MacDonald &nbsp;&nbsp;&nbsp;&nbsp;
 * <a href="mailto:donald@lifesci.dundee.ac.uk">donald@lifesci.dundee.ac.uk</a>
 * @version 3.0
 * <small>
 * (<b>Internal version:</b> $Revision: $Date: $)
 * </small>
 * @since 3.0-Beta4
 */
public class ScriptUploaderDialog 
	extends JDialog
	implements ActionListener, DocumentListener
{

	/** Bound property indicating to upload the script. */
	public static final String	UPLOAD_SCRIPT_PROPERTY = "uploadScript";
	
	/** The separator between first and last names. */
	private static final String	SEPARATOR = ", ";
	
    /** 
     * The size of the invisible components used to separate buttons
     * horizontally.
     */
    private static final Dimension	H_SPACER_SIZE = new Dimension(3, 10);
    
	/** The title of the dialog. */
	private static final String TITLE = "Upload Script";
	
	/** The text of the dialog. */
	private static final String TEXT = "Select the script to upload";
	
	/** Action ID indicating to upload the script to the server. */
	private static final int	SAVE = 0;
	
	/** Action ID indicating to close and disposes of the dialog. */
	private static final int	CANCEL = 1;

	/** Collection of supported filters. */
	private static final List<CustomizedFileFilter> FILTERS;
	
	static {
		FILTERS = new ArrayList<CustomizedFileFilter>();
		FILTERS.add(new CppFilter());
		FILTERS.add(new JavaFilter());
		FILTERS.add(new MatlabFilter());
		FILTERS.add(new PythonFilter());
	}
	
	/** Chooser used to select the file. */
	private JFileChooser chooser;
	
    /** 
     * Replaces the <code>ApproveButton</code> provided by the 
     * {@link JFileChooser} class. 
     */
    private JButton		saveButton;
    
    /** 
     * Replaces the <code>CancelButton</code> provided by the 
     * {@link JFileChooser} class. 
     */
    private JButton		cancelButton;

    /** Component used to enter the author of the script. */
    private JTextField	author;
    
    /** Component used to enter the author's e-mail address. */
    private JTextField	eMail;
    
    /** Component used to enter the author's institution. */
    private JTextField	institution;
    
    /** Component used to enter the description of the script. */
    private JTextField	description;
    
    /** Component used to enter where the script was published if 
     * published. */
    private JTextField	journalRef;
    
    /** The text area where to enter the name of the file to save. */
    private JTextField	scriptArea;
   
    /** The available scripts. */
    private Map<Long, String> scripts;
    
	/** Initializes the components. */
	private void initComponents()
	{
		chooser = new JFileChooser();
		chooser.setAcceptAllFileFilterUsed(false);
		chooser.setDialogType(JFileChooser.SAVE_DIALOG);
		Iterator<CustomizedFileFilter> i = FILTERS.iterator();
		while (i.hasNext()) {
			chooser.addChoosableFileFilter(i.next());
		}
		chooser.setControlButtonsAreShown(false);
		saveButton = new JButton("Upload");
		saveButton.setToolTipText(
				UIUtilities.formatToolTipText("Upload the selected script " +
						"to the server."));
		saveButton.addActionListener(this);
		saveButton.setActionCommand(""+SAVE);
		cancelButton = new JButton("Cancel");
		cancelButton.setToolTipText(
				UIUtilities.formatToolTipText("Closes the dialog."));
        cancelButton.addActionListener(this);
        cancelButton.setActionCommand(""+CANCEL);
        ExperimenterData exp = TreeViewerAgent.getUserDetails();
        author = new JTextField(exp.getFirstName()+", "+exp.getLastName());
        eMail = new JTextField(exp.getEmail());
        institution = new JTextField(exp.getInstitution());
        journalRef = new JTextField(); 
        description = new JTextField();
        
        scriptArea = (JTextField) UIUtilities.findComponent(chooser, 
				JTextField.class);
		if (scriptArea != null) {
			scriptArea.setEnabled(false);
			scriptArea.getDocument().addDocumentListener(this);
		}
		saveButton.setEnabled(scriptArea == null);
	}
	
	/**
	 * Builds and lays out the controls.
	 * 
	 * @return See above.
	 */
	private JPanel buildControls()
	{
		double[][] size = {{TableLayout.PREFERRED, 5, TableLayout.FILL},
				{TableLayout.PREFERRED, TableLayout.PREFERRED, 
			TableLayout.PREFERRED, TableLayout.PREFERRED, 50}};
		JPanel details = new JPanel();
		details.setLayout(new TableLayout(size));
		int row = 0;
		JLabel l = UIUtilities.setTextFont("Author (First, Last):");
		details.add(l, "0, "+row+", LEFT, CENTER");
		details.add(author, "2, "+row);
		row++;
		l = UIUtilities.setTextFont("E-mail:");
		details.add(l, "0, "+row+", LEFT, CENTER");
		details.add(eMail, "2, "+row);
		row++;
		l = UIUtilities.setTextFont("Institution:");
		details.add(l, "0, "+row+", LEFT, CENTER");
		details.add(institution, "2, "+row);
		row++;
		l = UIUtilities.setTextFont("Journal Ref:");
		details.add(l, "0, "+row+", LEFT, CENTER");
		details.add(journalRef, "2, "+row);
		row++;
		l = UIUtilities.setTextFont("Script's Description:");
		details.add(l, "0, "+row+", LEFT, TOP");
		details.add(description, "2, "+row);
		
		JXTaskPane pane = new JXTaskPane();
		pane.setCollapsed(true);
		pane.setTitle("Script details");
		pane.add(details);
		JPanel controls = new JPanel();
    	controls.setLayout(new BorderLayout(0, 0));
    	controls.add(pane, BorderLayout.NORTH);
    	controls.add(buildToolbar(), BorderLayout.CENTER);
    	
    	JPanel p = new JPanel();
    	p.setLayout(new BorderLayout(0, 0));
    	p.add(chooser, BorderLayout.CENTER);
    	p.add(controls, BorderLayout.SOUTH);
		return p;
	}
	
	/** Builds and lays out the UI. */
	private void buildGUI()
	{
		IconManager icons = IconManager.getInstance();
		TitlePanel tp = new TitlePanel(TITLE, TEXT, 
				icons.getIcon(IconManager.UPLOAD_48));
		Container c = getContentPane();
		c.setLayout(new BorderLayout(0, 0));
		c.add(tp, BorderLayout.NORTH);
		c.add(buildControls(), BorderLayout.CENTER);
		if (JDialog.isDefaultLookAndFeelDecorated()) {
            boolean supportsWindowDecorations = 
            UIManager.getLookAndFeel().getSupportsWindowDecorations();
            if (supportsWindowDecorations)
                getRootPane().setWindowDecorationStyle(
                            JRootPane.FILE_CHOOSER_DIALOG);
        }
	}
	
    /**
     * Builds the tool bar.
     * 
     * @return See above
     */
    private JPanel buildToolbar()
    {
    	JPanel bar = new JPanel();
    	bar.setBorder(null);
    	bar.add(cancelButton);
    	bar.add(Box.createRigidArea(H_SPACER_SIZE));
    	bar.add(saveButton);
    	JPanel p = UIUtilities.buildComponentPanelRight(bar);
        p.setOpaque(true);
        return p;
    }
    
	/** Closes and disposes. */
	private void close()
	{
		setVisible(false);
		dispose();
	}
	
	/** Uploads the script to the server. */
	private void upload()
	{
		File f;
		if (scriptArea != null)
			f = new File(chooser.getCurrentDirectory().toString(), 
					scriptArea.getText());
		else f = chooser.getSelectedFile();

		Iterator<CustomizedFileFilter> i = FILTERS.iterator();
		boolean supported = false;
		CustomizedFileFilter filter;
		while (i.hasNext()) {
			filter = i.next();
			if (filter.accept(f)) {
				supported = true;
				break;
			}
		}
		if (!supported) {
			UserNotifier un = TreeViewerAgent.getRegistry().getUserNotifier();
			un.notifyInfo(TITLE, "The selected script does not seem to " +
					"be supported.");
			return;
		}
		
		if (scripts != null) {
			//File should not be null.
			String name = f.getName();
			Entry entry;
			Iterator j = scripts.entrySet().iterator();
			String value;
			supported = false;
			while (j.hasNext()) {
				entry = (Entry) j.next();
				value = (String) entry.getValue();
				if (value.equals(name)) {
					supported = true;
					break;
				}
			}
			if (supported) {
				MessageBox box = new MessageBox((JFrame) getOwner(), TITLE, 
						"A script with the same name already exists in " +
						"the system.\n" +
						"Do you still want to upload the script?");
				if (box.centerMsgBox() == MessageBox.NO_OPTION) 
					return;
			}
		}
		ScriptObject script = new ScriptObject(-1, f.getAbsolutePath());
		
		//Set info about the script.
		String value = journalRef.getText();
		if (value != null) script.setJournalRef(value.trim());
		value = description.getText();
		if (value != null) script.setDescription(value.trim());
		
		ExperimenterData exp = new ExperimenterData();
		value = author.getText();
		if (value == null) exp = TreeViewerAgent.getUserDetails();
		else {
			String[] v = value.split(SEPARATOR);
			if (v != null && v.length == 2) {
				exp.setFirstName(v[0].trim());
				exp.setLastName(v[1].trim());
			} else exp = TreeViewerAgent.getUserDetails(); 
		}
		value = eMail.getText();
		if (value != null) exp.setEmail(value.trim());
		value = institution.getText();
		if (value != null) exp.setInstitution(value.trim());
		firePropertyChange(UPLOAD_SCRIPT_PROPERTY, null, script);
		close();
	}
	
	 /** Sets the properties of the dialog. */
    private void setProperties()
    {
    	setTitle(TITLE);
        setModal(true);
    }
    
    /**
     * Sets the <code>enabled</code> flag of not the <code>Save</code> option 
     * depending on the length of the text entered in the {@link #scriptArea}.
     */
    private void handleTextUpdate()
    {
    	if (scriptArea == null) return; //should happen
    	String text = scriptArea.getText();
    	boolean b = false;
    	if (text != null && text.trim().length() > 0) {
    		b = true;
    		Iterator<CustomizedFileFilter> i = FILTERS.iterator();
    		boolean supported = false;
    		CustomizedFileFilter filter;
    		while (i.hasNext()) {
    			filter = i.next();
    			if (filter.accept(text)) {
    				supported = true;
    				break;
    			}
    		}
    		if (!supported) {
    			saveButton.setEnabled(false);
    			return;
    		}
    	}
    	saveButton.setEnabled(b);
    }
    
	/**
	 * Creates a new instance.
	 * 
	 * @param owner The owner of the dialog.
	 * @param scripts The scripts already uploaded.
	 */
	public ScriptUploaderDialog(JFrame owner, Map<Long, String> scripts)
	{
		super(owner);
		this.scripts = scripts;
		setProperties();
		initComponents();
		buildGUI();
		pack();
	}

	/**
	 * Uploads the script or closes the dialog.
	 * @see ActionListener#actionPerformed(ActionEvent)
	 */
	public void actionPerformed(ActionEvent e)
	{
		int index = Integer.parseInt(e.getActionCommand());
		switch (index) {
			case CANCEL:
				close();
				break;
			case SAVE:
				upload();
		}
	}
	
    /**
	 * Enables or not the <code>Save</code> option depending on the text 
	 * entered in the {@link #scriptArea}.
	 * @see DocumentListener#insertUpdate(DocumentEvent)
	 */
	public void insertUpdate(DocumentEvent e) { handleTextUpdate(); }

	/**
	 * Enables or not the <code>Save</code> option depending on the text 
	 * entered in the {@link #scriptArea}.
	 * @see DocumentListener#removeUpdate(DocumentEvent)
	 */
	public void removeUpdate(DocumentEvent e) { handleTextUpdate(); }
    
	/**
	 * Required by the {@link DocumentListener} I/F but no-op implementation
	 * in our case.
	 * @see DocumentListener#changedUpdate(DocumentEvent)
	 */
	public void changedUpdate(DocumentEvent e) {}
	
}