/*
 * org.openmicroscopy.shoola.agents.chainbuilder.data.ChainExecutionLoader
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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

package org.openmicroscopy.shoola.agents.chainbuilder.data;

//Java imports
import java.util.Collection;
import java.util.Iterator;

//Third-party libraries

//Application-internal dependencies
import org.openmicroscopy.shoola.agents.chainbuilder.ChainDataManager;
import org.openmicroscopy.shoola.agents.chainbuilder.data.layout.LayoutChainData;
import org.openmicroscopy.shoola.agents.chainbuilder.data.layout.LayoutNodeData;
import org.openmicroscopy.shoola.agents.zoombrowser.data.BrowserDatasetData;
import org.openmicroscopy.shoola.env.data.model.ChainExecutionData;
import org.openmicroscopy.shoola.env.data.model.ModuleExecutionData;
import org.openmicroscopy.shoola.env.data.model.NodeExecutionData;
import org.openmicroscopy.shoola.util.data.ContentGroup;
import org.openmicroscopy.shoola.util.data.ContentLoader;

/** 
 * A {@link ContentLoader} subclass for loading chain executions.
 * 
 * @author  Harry Hochheiser &nbsp;&nbsp;&nbsp;&nbsp;
 * 				<a href="mailto:hsh@nih.gov">hsh@nih.gov</a>
 *
 * @version 2.2
 * <small>
 * (<b>Internal version:</b> $Revision$ $Date$)
 * </small>
 * @since OME2.2
 */
public class ChainExecutionLoader extends ContentLoader
{
	private Collection chainExecutions = null;
	
	public ChainExecutionLoader(final ChainDataManager dataManager,
			final ContentGroup group) {
		super(dataManager,group);
		start();
	}	
	
	/**
	 * Do the work
	 */
	public Object getContents() {
		if (chainExecutions == null)  {
			chainExecutions = ((ChainDataManager) dataManager).getChainExecutions();
		}
		// reconcile
		reconcileExecutions();
	//	dumpExecutions();
		return chainExecutions;
	}
	
	private void reconcileExecutions() {
		ChainExecutionData chainExecution;
		BrowserDatasetData dataset;
		LayoutChainData  chain;
		int id;
		Iterator iter = chainExecutions.iterator();
		ChainDataManager chainDataManager = (ChainDataManager) dataManager;
		
		while (iter.hasNext()) {
			chainExecution = (ChainExecutionData) iter.next();
			chain = (LayoutChainData) chainExecution.getChain();
			id = chain.getID();
			chainExecution.setChain(chainDataManager.getChain(id));
			dataset = (BrowserDatasetData) chainExecution.getDataset();
			id = dataset.getID();
			
			/* if I've already seen this in the hash, then replace it with what
			 * I saw before. If the hash doesn't have it, this means that the 
			 * dataset actually belongs to a different user, so it wouldn't
			 * be in the hash. Leave the dataset
			 * that I retrieved with the execution 
			 */
			BrowserDatasetData otherDataset = chainDataManager.getDataset(id);
			if (otherDataset != null)
				chainExecution.setDataset(otherDataset);
			reconcileNodeExecutions(chainExecution);
		}
	}
	
	public void reconcileNodeExecutions(ChainExecutionData chainExecution) {
		Collection nodeExecs = chainExecution.getNodeExecutions();
		if (nodeExecs == null || nodeExecs.size() == 0)
			return;
		NodeExecutionData ne;
		Iterator iter = nodeExecs.iterator();
		while (iter.hasNext()) {
			ne = (NodeExecutionData) iter.next();
			reconcileNodeExecution(ne);
		}		
	}
	
	public void reconcileNodeExecution(NodeExecutionData ne) {
		LayoutNodeData n = (LayoutNodeData) ne.getAnalysisNode();
		ChainDataManager chainDataManager = (ChainDataManager) dataManager;
		int id = n.getID();
		ne.setAnalysisNode(chainDataManager.getAnalysisNode(id));
	}
	
	private void dumpExecutions() {
		Iterator iter = chainExecutions.iterator();
		ChainExecutionData exec;
		while (iter.hasNext()) {
			exec = (ChainExecutionData) iter.next();
			if (exec.getID() == 1)
				dumpExecution(exec);
		}
	}
		
	private void dumpExecution(ChainExecutionData exec) {
		System.err.println("\n\nChain excution: "+exec.getID());
		LayoutChainData chain = (LayoutChainData) exec.getChain();
		System.err.println(" .. chain "+chain.getID()+", "+chain.getName());
		
		BrowserDatasetData ds = (BrowserDatasetData) exec.getDataset();
		System.err.println(".. dataset "+ds.getID()+", "+ds.getName());
		System.err.println(".. time: "+exec.getTimestamp());
		dumpNodeExecutions(exec);
	}
	
	private void dumpNodeExecutions(ChainExecutionData exec) {
		Collection nodeExecs = exec.getNodeExecutions();
		if (nodeExecs == null || nodeExecs.size() == 0)
			return;
		NodeExecutionData ne;
		System.err.println("Nod executions...");
		Iterator iter = nodeExecs.iterator();
		while (iter.hasNext()) {
			ne = (NodeExecutionData) iter.next();
			dumpNodeExecution(ne);
		}
	}
	
	private void dumpNodeExecution(NodeExecutionData ne) {
		System.err.println("node execution..."+ne.getID());
		LayoutNodeData node = (LayoutNodeData) ne.getAnalysisNode();
		System.err.println("Node is "+ node.getID());
		ChainModuleData module = (ChainModuleData) node.getModule();
		System.err.println(" .. module .."+module.getID()+", "+module.getName());
		ModuleExecutionData mex = ne.getModuleExecution();
		System.err.println(" .. mex id is "+mex.getID());
		System.err.println(" .. mex status is "+mex.getStatus());
		System.err.println("... mex time is "+mex.getTimestamp());
	}
}