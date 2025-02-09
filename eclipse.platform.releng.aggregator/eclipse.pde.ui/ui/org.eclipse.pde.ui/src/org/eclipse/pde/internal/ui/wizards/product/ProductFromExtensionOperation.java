/*******************************************************************************
 *  Copyright (c) 2005, 2021 IBM Corporation and others.
 *
 *  This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License 2.0
 *  which accompanies this distribution, and is available at
 *  https://www.eclipse.org/legal/epl-2.0/
 *
 *  SPDX-License-Identifier: EPL-2.0
 *
 *  Contributors:
 *     IBM Corporation - initial API and implementation
 *******************************************************************************/
package org.eclipse.pde.internal.ui.wizards.product;

import java.util.*;
import org.eclipse.core.resources.IFile;
import org.eclipse.pde.core.plugin.*;
import org.eclipse.pde.internal.core.DependencyManager;
import org.eclipse.pde.internal.core.TargetPlatformHelper;
import org.eclipse.pde.internal.core.iproduct.IProduct;
import org.eclipse.pde.internal.core.iproduct.IProductModelFactory;

public class ProductFromExtensionOperation extends BaseProductCreationOperation {

	private String fId;

	public ProductFromExtensionOperation(IFile file, String productId) {
		super(file);
		fId = productId;
	}

	@Override
	protected void initializeProduct(IProduct product) {
		if (fId == null)
			return;
		IProductModelFactory factory = product.getModel().getFactory();
		initializeProductInfo(factory, product, fId);
		addPlugins(factory, product, getPlugins());
		super.initializeProduct(product);
	}

	private String[] getPlugins() {
		int lastDot = fId.lastIndexOf('.');
		if (lastDot == -1)
			return new String[0];

		Set<IPluginModelBase> plugins = new HashSet<>();
		// add plugin declaring product and its pre-reqs
		IPluginModelBase model = PluginRegistry.findModel(fId.substring(0, lastDot));
		if (model != null) {
			plugins.add(model);
		}

		// add plugin declaring product application and its pre-reqs
		IPluginElement element = getProductExtension(fId);
		if (element != null) {
			IPluginAttribute attr = element.getAttribute("application"); //$NON-NLS-1$
			if (attr != null) {
				String appId = attr.getValue();
				lastDot = appId.lastIndexOf('.');
				if (lastDot != -1) {
					model = PluginRegistry.findModel(appId.substring(0, lastDot));
					if (model != null) {
						plugins.add(model);
					}
				}
			}
		}
		Set<String> bundles = DependencyManager.getDependencies(plugins, new String[0],
				TargetPlatformHelper.getState(), false, false, Collections.emptySet());
		return bundles.toArray(String[]::new);
	}

}
