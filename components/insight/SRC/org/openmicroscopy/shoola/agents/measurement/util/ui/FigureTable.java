/*
 * org.openmicroscopy.shoola.agents.measurement.util.FigureTable 
 *
  *------------------------------------------------------------------------------
 *  Copyright (C) 2006-2007 University of Dundee. All rights reserved.
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
package org.openmicroscopy.shoola.agents.measurement.util.ui;


//Java imports
import javax.swing.DefaultCellEditor;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.TableCellEditor;
import javax.swing.table.TableCellRenderer;

//Third-party libraries

//Application-internal dependencies
import org.openmicroscopy.shoola.agents.measurement.util.model.AttributeField;
import org.openmicroscopy.shoola.agents.measurement.util.model.FigureTableModel;
import org.openmicroscopy.shoola.agents.measurement.util.model.ValueType;
import org.openmicroscopy.shoola.util.ui.PaintPot;

/** 
 * Displays the figures in a table.
 *
 * @author  Jean-Marie Burel &nbsp;&nbsp;&nbsp;&nbsp;
 * 	<a href="mailto:j.burel@dundee.ac.uk">j.burel@dundee.ac.uk</a>
 * @author	Donald MacDonald &nbsp;&nbsp;&nbsp;&nbsp;
 * 	<a href="mailto:donald@lifesci.dundee.ac.uk">donald@lifesci.dundee.ac.uk</a>
 * @version 3.0
 * <small>
 * (<b>Internal version:</b> $Revision: $Date: $)
 * </small>
 * @since OME3.0
 */
public class FigureTable
	extends JTable
{
	
	/** The model for the table. */
	private FigureTableModel tableModel;
	
	/**
	 * Creates a new instance.
	 * 
	 * @param model The model used by this table.
	 */
	public FigureTable(FigureTableModel model)
	{
		super(model);
		tableModel = model;
	}
	
	/**
	 * Returns the Field at the specified row.
	 * 
	 * @param row The selected row.
	 * @return See above.
	 */
	public AttributeField getFieldAt(int row)
	{
		return tableModel.getFieldAt(row);
	}
	
	/**
	 * Overridden to return a customized cell renderer.
	 * @see JTable#getCellRenderer(int, int)
	 */
	public TableCellRenderer getCellRenderer(int row, int column) 
	{
        return new InspectorCellRenderer();
    }

	/**
	 * Overridden to return the editor corresponding to the specified cell.
	 * @see JTable#getCellEditor(int, int)
	 */
	public TableCellEditor getCellEditor(int row, int col)
	{
		AttributeField field = tableModel.getFieldAt(row);
		InspectorCellRenderer 
			renderer = (InspectorCellRenderer) getCellRenderer(row, col);
		Object v = tableModel.getValueAt(row, col);
		if (field.getValueType() == ValueType.ENUM)
		{
			return new DefaultCellEditor((JComboBox)
				renderer.getTableCellRendererComponent(this,
					getValueAt(row, col), false, false, row, col));
		} else if (v instanceof Double || v instanceof Integer || 
				v instanceof Long || v instanceof String) {
			return new DefaultCellEditor((JTextField) renderer.
				getTableCellRendererComponent(this,
					getValueAt(row, col), false, false, row, col));
		} else if (v instanceof Boolean) {
			return new DefaultCellEditor((JCheckBox) renderer.
				getTableCellRendererComponent(this,
					getValueAt(row, col), false, false, row, col));
		} 
		return super.getCellEditor(row, col);
	}
	
}

