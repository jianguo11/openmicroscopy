/*
 *   $Id$
 *
 *   Copyright 2006 University of Dundee. All rights reserved.
 *   Use is subject to license terms supplied in LICENSE.txt
 */

package ome.tools.hibernate;

import java.util.Collection;
import java.util.Properties;

import org.springframework.beans.factory.FactoryBean;
import org.springframework.orm.hibernate3.FilterDefinitionFactoryBean;

import ome.conditions.InternalException;
import ome.model.internal.Details;
import ome.model.internal.Permissions;
import ome.model.internal.Permissions.Flag;
import ome.model.internal.Permissions.Right;
import ome.model.internal.Permissions.Role;
import ome.system.Roles;
import static ome.model.internal.Permissions.Role.*;
import static ome.model.internal.Permissions.Right.*;

/**
 * overrides {@link FilterDefinitionFactoryBean} in order to construct our
 * security filter in code and not in XML. This allows us to make use of the
 * knowledge within {@link Permissions}
 * 
 * With the addition of shares in 4.0, it is necessary to remove the security
 * filter if a share is active and allow loading to throw the necessary
 * exceptions.
 * 
 * @author Josh Moore, josh at glencoesoftware.com
 * @since 3.0
 * @see <a
 *      href="https://trac.openmicroscopy.org.uk/omero/ticket/117">ticket117</a>
 * @see <a
 *      href="https://trac.openmicroscopy.org.uk/omero/ticket/1154">ticket1154</a>
 */
public class SecurityFilter extends FilterDefinitionFactoryBean {

    static public final String is_share = "is_share";

    static public final String is_adminorpi = "is_adminorpi";

    static public final String is_nonprivate = "is_nonprivate";

    static public final String current_group = "current_group";

    static public final String current_user = "current_user";

    static public final String filterName = "securityFilter";

    static private final Properties parameterTypes = new Properties();

    static private String defaultFilterCondition;
    static {
        parameterTypes.setProperty(is_share, "java.lang.Boolean");
        parameterTypes.setProperty(is_adminorpi, "java.lang.Boolean");
        parameterTypes.setProperty(is_nonprivate, "java.lang.Boolean");
        parameterTypes.setProperty(current_group, "long");
        parameterTypes.setProperty(current_user, "long");
        // This can't be done statically because we need the securitySystem.
        defaultFilterCondition = "(\n"
                // Should handle hidden groups at the top-level
                // ticket:1784 - Allowing system objects to be read.
                + "\n  ( group_id = :current_group AND "
                + "\n     ( :is_nonprivate OR "
                + "\n       :is_adminorpi OR "
                + "\n       owner_id = :current_user"
                + "\n     )"
                + "\n  ) OR"
                + "\n  group_id = %s OR " // ticket:1794
                + "\n :is_share"
                + "\n)\n";
    }

    private final Roles roles;

    /**
     * default constructor which calls all the necessary setters for this
     * {@link FactoryBean}. Also constructs the {@link #defaultFilterCondition }
     * This query clause must be kept in sync with
     * {@link #passesFilter(Details, Long, Collection, Collection, boolean)}
     * 
     * @see #passesFilter(Details, Long, Collection, Collection, boolean)
     * @see FilterDefinitionFactoryBean#setFilterName(String)
     * @see FilterDefinitionFactoryBean#setParameterTypes(Properties)
     * @see FilterDefinitionFactoryBean#setDefaultFilterCondition(String)
     */
    public SecurityFilter() {
        this(new Roles());
    }

    public SecurityFilter(Roles roles) {
        this.roles = roles;
        this.setFilterName(filterName);
        this.setParameterTypes(parameterTypes);
        this.setDefaultFilterCondition(String.format(defaultFilterCondition,
                roles.getUserGroupId()));
    }

    /**
     * tests that the {@link Details} argument passes the security test that
     * this filter defines. The two must be kept in sync. This will be used
     * mostly by the
     * {@link OmeroInterceptor#onLoad(Object, java.io.Serializable, Object[], String[], org.hibernate.type.Type[])}
     * method.
     * 
     * @param d
     *            Details instance. If null (or if its {@link Permissions} are
     *            null all {@link Right rights} will be assumed.
     * @return true if the object to which this
     */
    public boolean passesFilter(Details d,
            Long currentGroupId, Long currentUserId,
            boolean nonPrivate, boolean adminOrPi, boolean share) {
        if (d == null || d.getPermissions() == null) {
            throw new InternalException("Details/Permissions null! "
                    + "Security system failure -- refusing to continue. "
                    + "The Permissions should be set to a default value.");
        }

        Long o = d.getOwner().getId();
        Long g = d.getGroup().getId();

        if (share) {
            return true;
        }

        // ticket:1434 - Only loading current objects is permitted.
        // This method will not be called with system types.
        // See BasicACLVoter
        // Also ticket:1784 allowing system objects to be read.
        // Also ticket:1791 allowing user objects to be read (also 1794)
        if (Long.valueOf(roles.getSystemGroupId()).equals(g) ||
                Long.valueOf(roles.getUserGroupId()).equals(g)) {
            return true;
        }

        if (!currentGroupId.equals(g)) {
            return false;
        }

        if (nonPrivate) {
            return true;
        }

        if (adminOrPi) {
            return true;
        }

        if (currentUserId.equals(o)) {
            return true;
        }

        return false;
    }

    // ~ Helpers
    // =========================================================================

    protected static String isGranted(Role role, Right right) {
        String bit = "" + Permissions.bit(role, right);
        String isGranted = String
                .format(
                        "(cast(permissions as bit(64)) & cast(%s as bit(64))) = cast(%s as bit(64))",
                        bit, bit);
        return isGranted;
    }

    protected static String isSet(Flag flag) {
        String bit = "" + Permissions.bit(flag);
        String isGranted = String
                .format(
                        "(cast(permissions as bit(64)) & cast(%s as bit(64))) = cast(%s as bit(64))",
                        bit, bit);
        return isGranted;
    }

}