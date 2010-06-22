/*
 *   $Id$
 *
 *   Copyright 2006 University of Dundee. All rights reserved.
 *   Use is subject to license terms supplied in LICENSE.txt
 */
package ome.services.licenses;

/**
 * (CLIENT) Exception thrown on license acquisition when no licenses
 * are available.
 * 
 * @author Josh Moore, josh.moore @ gmx.de
 * @since  3.0-RC1
 */
public class NoAvailableLicensesException extends LicenseException {

    private static final long serialVersionUID = -3912767194002701163L;

    public NoAvailableLicensesException(String msg) {
        super(msg);
    }

}