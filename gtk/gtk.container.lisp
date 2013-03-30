;;; ----------------------------------------------------------------------------
;;; gtk.container.lisp
;;;
;;; This file contains code from a fork of cl-gtk2.
;;; See <http://common-lisp.net/project/cl-gtk2/>.
;;;
;;; The documentation has been copied from the GTK+ 3 Reference Manual
;;; Version 3.4.1. See <http://www.gtk.org>. The API documentation of the
;;; Lisp Binding is available at <http://www.crategus.com/books/cl-cffi-gtk/>.
;;;
;;; Copyright (C) 2009 - 2011 Kalyanov Dmitry
;;; Copyright (C) 2011 - 2013 Dieter Kaiser
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU Lesser General Public License for Lisp
;;; as published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version and with a preamble to
;;; the GNU Lesser General Public License that clarifies the terms for use
;;; with Lisp programs and is referred as the LLGPL.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU Lesser General Public License for more details.
;;;
;;; You should have received a copy of the GNU Lesser General Public
;;; License along with this program and the preamble to the Gnu Lesser
;;; General Public License.  If not, see <http://www.gnu.org/licenses/>
;;; and <http://opensource.franz.com/preamble.html>.
;;; ----------------------------------------------------------------------------
;;;
;;; GtkContainer
;;;
;;; Base class for widgets which contain other widgets
;;;
;;; Synopsis
;;;
;;;     GtkContainer
;;;
;;;     GTK_IS_RESIZE_CONTAINER
;;;     GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID
;;;
;;;     gtk_container_add
;;;     gtk_container_remove
;;;     gtk_container_add_with_properties
;;;     gtk_container_get_resize_mode
;;;     gtk_container_set_resize_mode
;;;     gtk_container_check_resize
;;;     gtk_container_foreach
;;;     gtk_container_get_children
;;;     gtk_container_get_path_for_child
;;;     gtk_container_set_reallocate_redraws
;;;     gtk_container_get_focus_child
;;;     gtk_container_set_focus_child
;;;     gtk_container_get_focus_vadjustment
;;;     gtk_container_set_focus_vadjustment
;;;     gtk_container_get_focus_hadjustment
;;;     gtk_container_set_focus_hadjustment
;;;     gtk_container_resize_children
;;;     gtk_container_child_type
;;;     gtk_container_child_get
;;;     gtk_container_child_set
;;;     gtk_container_child_get_property
;;;     gtk_container_child_set_property
;;;     gtk_container_child_get_valist
;;;     gtk_container_child_set_valist
;;;     gtk_container_child_notify
;;;     gtk_container_forall
;;;     gtk_container_get_border_width
;;;     gtk_container_set_border_width
;;;     gtk_container_propagate_draw
;;;     gtk_container_get_focus_chain
;;;     gtk_container_set_focus_chain
;;;     gtk_container_unset_focus_chain
;;;     gtk_container_class_find_child_property
;;;     gtk_container_class_install_child_property
;;;     gtk_container_class_list_child_properties
;;;     gtk_container_class_handle_border_width
;;; ----------------------------------------------------------------------------

(in-package :gtk)

;;; ----------------------------------------------------------------------------
;;; struct GtkContainer
;;; ----------------------------------------------------------------------------

(define-g-object-class "GtkContainer" gtk-container
  (:superclass gtk-widget
   :export t
   :interfaces ("AtkImplementorIface" "GtkBuildable")
   :type-initializer "gtk_container_get_type")
  ((border-width
    gtk-container-border-width
    "border-width" "guint" t t)
   (child
    gtk-container-child
    "child" "GtkWidget" nil t)
   (resize-mode
    gtk-container-resize-mode
    "resize-mode" "GtkResizeMode" t t)))

;;; ----------------------------------------------------------------------------

#+cl-cffi-gtk-documentation
(setf (documentation 'gtk-container 'type)
 "@version{2013-1-4}
  @short{Base class for widgets which contain other widgets.}

  A GTK+ user interface is constructed by nesting widgets inside widgets.
  Container widgets are the inner nodes in the resulting tree of widgets: they
  contain other widgets. So, for example, you might have a @class{gtk-window}
  containing a @class{gtk-frame} containing a @class{gtk-label}. If you wanted
  an image instead of a textual label inside the frame, you might replace the
  @class{gtk-label} widget with a @class{gtk-image} widget.

  There are two major kinds of container widgets in GTK+. Both are subclasses
  of the abstract @sym{gtk-container} base class.

  The first type of container widget has a single child widget and derives
  from @class{gtk-bin}. These containers are decorators, which add some kind of
  functionality to the child. For example, a @class{gtk-button} makes its child
  into a clickable button; a @class{gtk-frame} draws a frame around its child
  and a @class{gtk-window} places its child widget inside a top-level window.

  The second type of container can have more than one child; its purpose is to
  manage layout. This means that these containers assign sizes and positions
  to their children. For example, a @class{gtk-hbox} arranges its children in a
  horizontal row, and a @class{gtk-grid} arranges the widgets it contains in a
  two-dimensional grid.

  @heading{Height for width geometry management}
  GTK+ uses a height-for-width (and width-for-height) geometry management
  system. Height-for-width means that a widget can change how much vertical
  space it needs, depending on the amount of horizontal space that it is given
  (and similar for width-for-height).

  There are some things to keep in mind when implementing container widgets
  that make use of GTK+'s height for width geometry management system. First,
  it's important to note that a container must prioritize one of its
  dimensions, that is to say that a widget or container can only have a
  @symbol{gtk-size-request-mode} that is @code{:height-for-width} or
  @code{:width-for-height}. However, every widget and container must
  be able to respond to the APIs for both dimensions, i.e. even if a widget
  has a request mode that is height-for-width, it is possible that its parent
  will request its sizes using the width-for-height APIs.

  To ensure that everything works properly, here are some guidelines to follow
  when implementing height-for-width (or width-for-height) containers.

  Each request mode involves 2 virtual methods. Height-for-width apis run
  through @fun{gtk-widget-get-preferred-width} and then through
  @fun{gtk-widget-get-preferred-height-for-width}. When handling requests in the
  opposite @symbol{gtk-size-request-mode} it is important that every widget
  request at least enough space to display all of its content at all times.

  When @fun{gtk-widget-get-preferred-height} is called on a container that is
  height-for-width, the container must return the height for its minimum
  width. This is easily achieved by simply calling the reverse apis
  implemented for itself as follows:
  @begin{pre}
  static void
  foo_container_get_preferred_height (GtkWidget *widget,
                                      gint *min_height, gint *nat_height)
  {
     if (i_am_in_height_for_width_mode)
       {
         gint min_width;

         GTK_WIDGET_GET_CLASS (widget)->
                    get_preferred_width (widget, &min_width, NULL);
         GTK_WIDGET_GET_CLASS (widget)->
                    get_preferred_height_for_width (widget,
                                                    min_width,
                                                    min_height, nat_height);
       @}
     else
       {
         ... many containers support both request modes, execute the real
         width-for-height request here by returning the collective heights of
         all widgets that are stacked vertically (or whatever is appropriate
         for this container) ...
       @}
  @}
  @end{pre}
  Similarly, when @fun{gtk-widget-get-preferred-width-for-height} is called for
  a container or widget that is height-for-width, it then only needs to return
  the base minimum width like so:
  @begin{pre}
  static void
  foo_container_get_preferred_width_for_height (GtkWidget *widget,
                                                gint for_height,
                                                gint *min_width,
                                                gint *nat_width)
  {
     if (i_am_in_height_for_width_mode)
       {
         GTK_WIDGET_GET_CLASS (widget)->
                    get_preferred_width (widget, min_width, nat_width);
       @}
     else
       {
         ... execute the real width-for-height request here based on the
         required width of the children collectively if the container were to
         be allocated the said height ...
       @}
  @}
  @end{pre}
  Height for width requests are generally implemented in terms of a virtual
  allocation of widgets in the input orientation. Assuming an height-for-width
  request mode, a container would implement the
  @code{get_preferred_height_for_width()} virtual function by first calling
  @fun{gtk-widget-get-preferred-width} for each of its children.

  For each potential group of children that are lined up horizontally, the
  values returned by @fun{gtk-widget-get-preferred-width} should be collected in
  an array of @class{gtk-requested-size} structures. Any child spacing should
  be removed from the input for_width and then the collective size should be
  allocated using the @code{gtk_distribute_natural_allocation()} convenience
  function.

  The container will then move on to request the preferred height for each
  child by using @fun{gtk-widget-get-preferred-height-for-width} and using the
  sizes stored in the @class{gtk-requested-size} array.

  To allocate a height-for-width container, it's again important to consider
  that a container must prioritize one dimension over the other. So if a
  container is a height-for-width container it must first allocate all widgets
  horizontally using a @class{gtk-requested-size} array and
  @code{gtk_distribute_natural_allocation()} and then add any extra space (if
  and where appropriate) for the widget to expand.

  After adding all the expand space, the container assumes it was allocated
  sufficient height to fit all of its content. At this time, the container
  must use the total horizontal sizes of each widget to request the
  height-for-width of each of its children and store the requests in a
  @class{gtk-requested-size} array for any widgets that stack vertically (for
  tabular containers this can be generalized into the heights and widths of rows
  and columns). The vertical space must then again be distributed using
  @code{gtk_distribute_natural_allocation()} while this time considering the
  allocated height of the widget minus any vertical spacing that the container
  adds. Then vertical expand space should be added where appropriate and
  available and the container should go on to actually allocating the child
  widgets.

  See @class{gtk-widget}'s geometry management section to learn more about
  implementing height-for-width geometry management for widgets.

  @heading{Child properties}
  @sym{gtk-container} introduces child properties. These are object properties
  that are not specific to either the container or the contained widget, but
  rather to their relation. Typical examples of child properties are the
  position or pack-type of a widget which is contained in a @class{gtk-box}.

  Use @code{gtk_container_class_install_child_property()} to install child
  properties for a container class and
  @fun{gtk-container-class-find-child-property} or
  @fun{gtk-container-class-list-child-properties} to get information about
  existing child properties.

  To set the value of a child property, use
  @fun{gtk-container-child-set-property}, @code{gtk_container_child_set()} or
  @code{gtk_container_child_set_valist()}. To obtain the value of a child
  property, use @fun{gtk-container-child-get-property},
  @code{gtk_container_child_get()} or @code{gtk_container_child_get_valist()}.
  To emit notification about child property changes, use
  @fun{gtk-widget-child-notify}.

  @heading{GtkContainer as GtkBuildable}
  The @sym{gtk-container} implementation of the @class{gtk-buildable} interface
  supports a @code{<packing>} element for children, which can contain multiple
  @code{<property>} elements that specify child properties for the child.

  Example 105. Child properties in UI definitions
  @begin{pre}
  <object class=\"GtkVBox\">
    <child>
      <object class=\"GtkLabel\"/>
      <packing>
        <property name=\"pack-type\">start</property>
      </packing>
    </child>
  </object>
  @end{pre}
  Since 2.16, child properties can also be marked as translatable using the
  same \"translatable\", \"comments\" and \"context\" attributes that are used
  for regular properties.
  @begin[Signal Details]{dictionary}
    @b{The \"add\" signal}
    @begin{pre}
 void user_function (GtkContainer *container,
                    GtkWidget    *widget,
                    gpointer      user_data)      : Run First
    @end{pre}
    @b{The \"check-resize\" signal}
    @begin{pre}
 void user_function (GtkContainer *container,
                     gpointer      user_data)      : Run Last
    @end{pre}
    @b{The \"remove\" signal}
    @begin{pre}
 void user_function (GtkContainer *container,
                     GtkWidget    *widget,
                     gpointer      user_data)      : Run First
    @end{pre}
    @b{The \"set-focus-child\" signal}
    @begin{pre}
 void user_function (GtkContainer *container,
                     GtkWidget    *widget,
                     gpointer      user_data)      : Run First
    @end{pre}
  @end{dictionary}
  @see-slot{gtk-container-border-width}
  @see-slot{gtk-container-child}
  @see-slot{gtk-container-resize-mode}")

;;; ----------------------------------------------------------------------------
;;;
;;; Property Details
;;;
;;; ----------------------------------------------------------------------------

#+cl-cffi-gtk-documentation
(setf (documentation (atdoc:get-slot-from-name "border-width" 'gtk-container) 't)
 "@version{2013-1-4}
  The @code{\"border-width\"} property of type @code{guint} (Read / Write).@br{}
  The width of the empty border outside the containers children.@br{}
  Allowed values: @code{<= 65535}@br{}
  Default value: @code{0}")

#+cl-cffi-gtk-documentation
(setf (documentation (atdoc:get-slot-from-name "child" 'gtk-container) 't)
 "@version{2013-1-4}
  The @code{\"child\"} property of type @class{gtk-widget} (Write).@br{}
  Can be used to add a new child to the container.")

#+cl-cffi-gtk-documentation
(setf (documentation (atdoc:get-slot-from-name "resize-mode" 'gtk-container) 't)
 "@version{2013-1-4}
  The @code{\"resize-mode\"} property of type @symbol{gtk-resize-mode}
  (Read / Write).@br{}
  Specify how resize events are handled.@br{}
  Default value: @code{:parent}")

;;; ----------------------------------------------------------------------------
;;;
;;; Accessors
;;;
;;; ----------------------------------------------------------------------------

;;; --- gtk-container-border-width ---------------------------------------------

#+cl-cffi-gtk-documentation
(setf (gethash 'gtk-container-border-width atdoc:*function-name-alias*) "Accessor"
      (documentation 'gtk-container-border-width 'function)
 "@version{2013-1-4}
  @begin{short}
    Accessor of the slot @code{border-width} of the @class{gtk-container} class.
  @end{short}
  See the function @fun{gtk-container-set-border-width} for details.
  @see-function{gtk-container-set-border-width}")

;;; --- gtk-container-child ----------------------------------------------------

#+cl-cffi-gtk-documentation
(setf (gethash 'gtk-container-child atdoc:*function-name-alias*) "Accessor"
      (documentation 'gtk-container-child 'function)
 "@version{2013-1-20}
  @begin{short}
    Accessor of the slot @code{child} of the @class{gtk-container} class.
  @end{short}")

;;; --- gtk-container-resize-mode ----------------------------------------------

#+cl-cffi-gtk-documentation
(setf (gethash 'gtk-container-resize-mode atdoc:*function-name-alias*) "Accessor"
      (documentation 'gtk-container-resize-mode 'function)
 "@version{2013-1-4}
  @begin{short}
    Accessor of the slot @code{resize-mode} of the @class{gtk-container} class.
  @end{short}
  See the function @fun{gtk-container-set-resize-mode} for details.
  @see-function{gtk-container-set-resize-mode}")

;;; ----------------------------------------------------------------------------
;;; GTK_IS_RESIZE_CONTAINER()
;;;
;;; #define GTK_IS_RESIZE_CONTAINER(widget)
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID()
;;;
;;; #define GTK_CONTAINER_WARN_INVALID_CHILD_PROPERTY_ID (object,
;;;                                                       property_id, pspec)
;;;
;;; This macro should be used to emit a standard warning about unexpected
;;; properties in set_child_property() and get_child_property() implementations.
;;;
;;; object :
;;;     the GObject on which set_child_property() or get_child_property() was
;;;     called
;;;
;;; property_id :
;;;     the numeric id of the property
;;;
;;; pspec :
;;;     the GParamSpec of the property
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_add ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_add" gtk-container-add) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-1-20}
  @argument[container]{a @class{gtk-container} instance}
  @argument[widget]{a @arg{widget} to be placed inside @arg{container}}
  @short{Adds @arg{widget} to @arg{container}.}
  Typically used for simple containers such as @class{gtk-window},
  @class{gtk-frame}, or @class{gtk-button}; for more complicated layout
  containers such as @class{gtk-box} or @class{gtk-grid}, this function will
  pick default packing parameters that may not be correct. So consider functions
  such as @fun{gtk-box-pack-start} and @fun{gtk-grid-attach} as an
  alternative to @sym{gtk-container-add} in those cases. A widget may be added
  to only one container at a time; you can't place the same widget inside two
  different containers.
  @see-function{gtk-box-pack-start}
  @see-function{gtk-grid-attach}"
  (container (g-object gtk-container))
  (widget (g-object gtk-widget)))

(export 'gtk-container-add)

;;; ----------------------------------------------------------------------------
;;; gtk_container_remove ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_remove" gtk-container-remove) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[widget]{a current child of @arg{container}}
  @short{Removes widget from container.}
  @arg{widget} must be inside @arg{container}. Note that @arg{container} will
  own a reference to @arg{widget}, and that this may be the last reference held;
  so removing a widget from its container can destroy that widget. If you want
  to use @arg{widget} again, you need to add a reference to it while it's not
  inside a container, using @fun{g-object-ref}. If you don't want to use
  @arg{widget} again it's usually more efficient to simply destroy it directly
  using @fun{gtk-widget-destroy} since this will remove it from the
  @arg{container} and help break any circular reference count cycles."
  (container (g-object gtk-container))
  (widget (g-object gtk-widget)))

(export 'gtk-container-remove)

;;; ----------------------------------------------------------------------------
;;; gtk_container_add_with_properties ()
;;;
;;; void gtk_container_add_with_properties (GtkContainer *container,
;;;                                         GtkWidget *widget,
;;;                                         const gchar *first_prop_name,
;;;                                         ...);
;;;
;;; Adds widget to container, setting child properties at the same time.
;;; See gtk_container_add() and gtk_container_child_set() for more details.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; widget :
;;;     a widget to be placed inside container
;;;
;;; first_prop_name :
;;;     the name of the first child property to set
;;;
;;; ... :
;;;     a NULL-terminated list of property names and values, starting with
;;;     first_prop_name
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_resize_mode ()
;;; ----------------------------------------------------------------------------

(declaim (inline gtk-container-get-resize-mode))

(defun gtk-container-get-resize-mode (container)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @return{The current resize mode.}
  @short{Returns the resize mode for the container.}
  See @fun{gtk-container-set-resize-mode}.
  @see-function{gtk-container-set-resize-mode}"
  (gtk-container-resize-mode container))

(export 'gtk-container-get-resize-mode)

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_resize_mode ()
;;; ----------------------------------------------------------------------------

(declaim (inline gtk-container-set-resize-mode))

(defun gtk-container-set-resize-mode (container resize-mode)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[resize-mode]{The new resize mode.}
  @short{Sets the resize mode for the container.}

  The resize mode of a container determines whether a resize request will be
  passed to the container's parent, queued for later execution or executed
  immediately."
  (setf (gtk-container-resize-mode container) resize-mode))

(export 'gtk-container-set-resize-mode)

;;; ----------------------------------------------------------------------------
;;; gtk_container_check_resize ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_check_resize" gtk-container-check-resize) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @short{undocumented}"
  (container g-object))

(export 'gtk-container-check-resize)

;;; ----------------------------------------------------------------------------
;;; gtk_container_foreach ()
;;; ----------------------------------------------------------------------------

(defcallback gtk-container-foreach-callback :void
    ((widget (g-object gtk-widget)) (data :pointer))
  (restart-case
      (funcall (glib::get-stable-pointer-value data)
               widget)
    (return () nil)))

(defcfun ("gtk_container_foreach" %gtk-container-foreach) :void
  (container (g-object gtk-container))
  (callback :pointer)
  (data :pointer))

(defun gtk-container-foreach (container func)
 #+cl-cffi-gtk-documentation
 "@version{2013-2-26}
  @argument[container]{a @class{gtk-container} widget}
  @argument[func]{a Lisp function which is passed as a callback to the C
    function @code{gtk_container_foreach()}}
  @begin{short}
    Invokes @arg{func} on each non-internal child of @arg{container}.
  @end{short}
  See gtk_container_forall() for details on what constitutes an \"internal\"
  child. Most applications should use @sym{gtk-container-foreach}, rather than
  gtk_container_forall()."
  (with-stable-pointer (ptr func)
    (%gtk-container-foreach container
                            (callback gtk-container-foreach-callback)
                            ptr)))

(export 'gtk-container-foreach)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_children ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_get_children" gtk-container-get-children)
    (g-list g-object :free-from-foreign t)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @return{a newly-allocated list of the container's non-internal children}
  @short{Returns the container's non-internal children.}
  See gtk_container_forall() for details on what constitutes an \"internal\"
  child."
  (container g-object))

(export 'gtk-container-get-children)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_path_for_child ()
;;;
;;; GtkWidgetPath * gtk_container_get_path_for_child (GtkContainer *container,
;;;                                                   GtkWidget *child);
;;;
;;; Returns a newly created widget path representing all the widget hierarchy
;;; from the toplevel down to and including child.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a child of container
;;;
;;; Returns :
;;;     A newly created GtkWidgetPath
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_reallocate_redraws ()
;;; ----------------------------------------------------------------------------

(declaim (inline gtk-container-set-reallocate-redraws))

(defun gtk-container-set-reallocate-redraws (container need-redraws)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[needs-redraws]{the new value for the container's reallocate_redraws
    flag}
  @begin{short}
    Sets the reallocate_redraws flag of the container to the given value.
  @end{short}

  Containers requesting reallocation redraws get automatically redrawn if any
  of their children changed allocation."
  (setf (gtk-container-reallocate-redraws container) need-redraws))

(export 'gtk-container-set-reallocate-redraws)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_focus_child ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_get_focus_child" gtk-container-get-focus-child)
    (g-object gtk-widget)
 #+cl-cffi-gtk-documentation
 "@version{2013-2-26}
  @argument[container]{a @class{gtk-container} instance}
  @return{The child widget which will receive the focus inside container when
    the conatiner is focussed, or NULL if none is set.}
  @short{Returns the current focus child widget inside container.}
  This is not the currently focused widget. That can be obtained by calling
  @fun{gtk-window-get-focus}.

  Since 2.14
  @see-function{gtk-window-get-focus}"
  (container (g-object gtk-container)))

(export 'gtk-container-get-focus-child)

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_focus_child ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_set_focus_child" gtk-container-set-focus-child) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-2-26}
  @argument[container]{a @class{gtk-container} instance}
  @argument[child]{a GtkWidget, or NULL}
  @short{Sets, or unsets if child is NULL, the focused child of container.}

  This function emits the GtkContainer::set_focus_child signal of container.
  Implementations of GtkContainer can override the default behaviour by
  overriding the class closure of this signal.

  This is function is mostly meant to be used by widgets. Applications can use
  gtk_widget_grab_focus() to manualy set the focus to a specific widget."
  (container (g-object gtk-container))
  (child (g-object gtk-widget)))

(export 'gtk-container-set-focus-child)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_focus_vadjustment ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_get_focus_vadjustment"
           gtk-container-get-focus-vadjustment) (g-object gtk-adjustment)
 #+cl-cffi-gtk-documentation
 "@version{2013-2-26}
  @argument[container]{a @class{gtk-container} instance}
  @return{the vertical focus adjustment, or NULL if none has been set}
  @short{Retrieves the vertical focus adjustment for the container.}
  See @fun{gtk-container-set-focus-vadjustment}.
  @see-function{gtk-container-set-focus-vadjustment}"
  (container (g-object gtk-container)))

(export 'gtk-container-get-focus-vadjustment)

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_focus_vadjustment ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_set_focus_vadjustment"
           gtk-container-set-focus-vadjustment) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-2-26}
  @argument[container]{a @class{gtk-container} instance}
  @argument[adjustment]{an adjustment which should be adjusted when the focus is
    moved among the descendents of container}
  @begin{short}
    Hooks up an adjustment to focus handling in a container, so when a child of
    the container is focused, the adjustment is scrolled to show that widget.
  @end{short}
  This function sets the vertical alignment. See
  @fun{gtk-scrolled-window-get-vadjustment} for a typical way of obtaining the
  adjustment and @fun{gtk-container-set-focus-hadjustment} for setting the
  horizontal adjustment.

  The adjustments have to be in pixel units and in the same coordinate system
  as the allocation for immediate children of the container."
  (container (g-object gtk-container))
  (adjustment (g-object gtk-adjustment)))

(export 'gtk-container-set-focus-vadjustment)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_focus_hadjustment ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_get_focus_hadjustment"
           gtk-container-get-focus-hadjustment) (g-object gtk-adjustment)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @return{the horizontal focus adjustment, or NULL if none has been set}
  @short{Retrieves the horizontal focus adjustment for the container.}
  See @fun{gtk-container-set-focus-hadjustment}."
  (container (g-object gtk-container)))

(export 'gtk-container-get-focus-hadjustment)

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_focus_hadjustment ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_set_focus_hadjustment"
           gtk-container-set-focus-hadjustment) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[adjustment]{an adjustment which should be adjusted when the focus is
    moved among the descendents of container}
  @begin{short}
    Hooks up an adjustment to focus handling in a container, so when a child of
    the container is focused, the adjustment is scrolled to show that widget.
  @end{short}
  This function sets the horizontal alignment. See
  gtk_scrolled_window_get_hadjustment() for a typical way of obtaining the
  adjustment and gtk_container_set_focus_vadjustment() for setting the
  vertical adjustment.

  The adjustments have to be in pixel units and in the same coordinate system
  as the allocation for immediate children of the container."
  (container (g-object gtk-container))
  (adjustment (g-object gtk-adjustment)))

(export 'gtk-container-set-focus-hadjustment)

;;; ----------------------------------------------------------------------------
;;; gtk_container_resize_children ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_resize_children" gtk-container-resize-children) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @short{undocumented}"
  (container g-object))

(export 'gtk-container-resize-children)

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_type ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_child_type" gtk-container-child-type) g-type
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @return{a GType}
  @short{Returns the type of the children supported by the container.}

  Note that this may return G_TYPE_NONE to indicate that no more children can
  be added, e.g. for a GtkPaned which already has two children."
  (container g-object))

(export 'gtk-container-child-type)

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_get ()
;;;
;;; void gtk_container_child_get (GtkContainer *container,
;;;                               GtkWidget *child,
;;;                               const gchar *first_prop_name,
;;;                               ...);
;;;
;;; Gets the values of one or more child properties for child and container.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a widget which is a child of container
;;;
;;; first_prop_name :
;;;     the name of the first property to get
;;;
;;; ... :
;;;     return location for the first property, followed optionally by more
;;;     name/return location pairs, followed by NULL
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_set ()
;;;
;;; void gtk_container_child_set (GtkContainer *container,
;;;                               GtkWidget *child,
;;;                               const gchar *first_prop_name,
;;;                               ...);
;;;
;;; Sets one or more child properties for child and container.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a widget which is a child of container
;;;
;;; first_prop_name :
;;;     the name of the first property to set
;;;
;;; ... :
;;;     a NULL-terminated list of property names and values, starting with
;;;     first_prop_name
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_get_property ()
;;; ----------------------------------------------------------------------------

;; TODO: Consider to return the value in the Lisp implementation

(defcfun ("gtk_container_child_get_property" gtk-container-child-get-property)
    :void
 #+cl-cffi-gtk-documentation
 "@version{2013-3-26}
  @argument[container]{a @class{gtk-container} widget}
  @argument[child]{a widget which is a child of @arg{container}}
  @argument[property-name]{the name of the property to get}
  @argument[value]{a location to return the value}
  Gets the value of a child property for @arg{child} and @arg{container}."
  (container g-object)
  (child g-object)
  (property-name :string)
  (value (:pointer g-value)))

(export 'gtk-container-child-get-property)

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_set_property ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_child_set_property" gtk-container-child-set-property)
    :void
 #+cl-cffi-gtk-documentation
 "@version{2013-3-26}
  @argument[container]{a @class{gtk-container} widget}
  @argument[child]{a widget which is a child of @arg{container}}
  @argument[property-name]{the name of the property to set}
  @argument[value]{the value to set the property to}
  Sets a child property for child and container."
  (container g-object)
  (child g-object)
  (property-name :string)
  (value (:pointer g-value)))

(export 'gtk-container-child-set-property)

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_get_valist ()
;;;
;;; void gtk_container_child_get_valist (GtkContainer *container,
;;;                                      GtkWidget *child,
;;;                                      const gchar *first_property_name,
;;;                                      va_list var_args);
;;;
;;; Gets the values of one or more child properties for child and container.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a widget which is a child of container
;;;
;;; first_property_name :
;;;     the name of the first property to get
;;;
;;; var_args :
;;;     return location for the first property, followed optionally by more
;;;     name/return location pairs, followed by NULL
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_set_valist ()
;;;
;;; void gtk_container_child_set_valist (GtkContainer *container,
;;;                                      GtkWidget *child,
;;;                                      const gchar *first_property_name,
;;;                                      va_list var_args);
;;;
;;; Sets one or more child properties for child and container.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a widget which is a child of container
;;;
;;; first_property_name :
;;;     the name of the first property to set
;;;
;;; var_args :
;;;     a NULL-terminated list of property names and values, starting with
;;;     first_prop_name
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_child_notify ()
;;;
;;; void gtk_container_child_notify (GtkContainer *container,
;;;                                  GtkWidget *child,
;;;                                  const gchar *child_property);
;;;
;;; Emits a "child-notify" signal for the child property child_property on
;;; widget.
;;;
;;; This is an analogue of g_object_notify() for child properties.
;;;
;;; Also see gtk_widget_child_notify().
;;;
;;; container :
;;;     the GtkContainer
;;;
;;; child :
;;;     the child widget
;;;
;;; child_property :
;;;     the name of a child property installed on the class of container
;;;
;;; Since 3.2
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_forall ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_forall" %gtk-container-forall) :void
  (container g-object)
  (callback :pointer)
  (data :pointer))

(defun gtk-container-forall (container function)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[callback]{a callback}
  @arguemnt[callback_data]{callback user data}
  @begin{short}
    Invokes callback on each child of container, including children that are
    considered \"internal\" (implementation details of the container).
  @end{short}
  \"Internal\" children generally weren't added by the user of the container,
  but were added by the container implementation itself. Most applications
  should use gtk_container_foreach(), rather than gtk_container_forall()."
  (with-stable-pointer (ptr function)
    (%gtk-container-forall container
                           (callback gtk-container-foreach-callback)
                           ptr)))

(export 'gtk-container-forall)

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_border_width ()
;;; ----------------------------------------------------------------------------

(declaim (inline gtk-container-get-border-width))

(defun gtk-container-get-border-width (container)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @return{the current border width}
  @short{Retrieves the border width of the container.}
  See @fun{gtk-container-set-border-width}.
  @see-function{gtk-container-set-border-width}"
  (gtk-container-border-width container))

(export 'gtk-container-get-border-width)

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_border_width ()
;;; ----------------------------------------------------------------------------

(declaim (inline gtk-container-set-border-width))

(defun gtk-container-set-border-width (container border-width)
 #+cl-cffi-gtk-documentation
 "@version{2013-1-4}
  @argument[container]{a @class{gtk-container} instance}
  @argument[border_width]{amount of blank space to leave outside the container.
    Valid values are in the range 0-65535 pixels.}
  @short{Sets the border width of the container.}

  The border width of a container is the amount of space to leave around the
  outside of the container. The only exception to this is @class{gtk-window};
  because toplevel windows can't leave space outside, they leave the space
  inside. The border is added on all sides of the container. To add space to
  only one side, one approach is to create a @class{gtk-alignment} widget, call
  @fun{gtk-widget-set-size-request} to give it a size, and place it on the side
  of the container as a spacer."
  (setf (gtk-container-border-width container) border-width))

(export 'gtk-container-set-border-width)

;;; ----------------------------------------------------------------------------
;;; gtk_container_propagate_draw ()
;;;
;;; void gtk_container_propagate_draw (GtkContainer *container,
;;;                                    GtkWidget *child,
;;;                                    cairo_t *cr);
;;;
;;; When a container receives a call to the draw function, it must send
;;; synthetic "draw" calls to all children that don't have their own GdkWindows.
;;; This function provides a convenient way of doing this. A container, when it
;;; receives a call to its "draw" function, calls gtk_container_propagate_draw()
;;; once for each child, passing in the cr the container received.
;;;
;;; gtk_container_propagate_draw() takes care of translating the origin of cr,
;;; and deciding whether the draw needs to be sent to the child. It is a
;;; convenient and optimized way of getting the same effect as calling
;;; gtk_widget_draw() on the child directly.
;;;
;;; In most cases, a container can simply either inherit the "draw"
;;; implementation from GtkContainer, or do some drawing and then chain to the
;;; ::draw implementation from GtkContainer.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; child :
;;;     a child of container
;;;
;;; cr :
;;;     Cairo context as passed to the container. If you want to use cr in
;;;     container's draw function, consider using cairo_save() and
;;;     cairo_restore() before calling this function.
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_get_focus_chain ()
;;;
;;; gboolean gtk_container_get_focus_chain (GtkContainer *container,
;;;                                         GList **focusable_widgets);
;;;
;;; Retrieves the focus chain of the container, if one has been set explicitly.
;;; If no focus chain has been explicitly set, GTK+ computes the focus chain
;;; based on the positions of the children. In that case, GTK+ stores NULL in
;;; focusable_widgets and returns FALSE.
;;;
;;; container :
;;;     a GtkContainer
;;;
;;; focusable_widgets :
;;;     location to store the focus chain of the container, or NULL. You should
;;;     free this list using g_list_free() when you are done with it, however no
;;;     additional reference count is added to the individual widgets in the
;;;     focus chain.
;;;
;;; Returns :
;;;     TRUE if the focus chain of the container has been set explicitly.
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_set_focus_chain ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_set_focus_chain" gtk-container-set-focus-chain) :void
 #+cl-cffi-gtk-documentation
 "@version{2013-3-10}
  @argument[container]{a @class{gtk-container} widget}
  @argument[focusable-widgets]{the new focus chain}
  @begin{short}
    Sets a focus chain, overriding the one computed automatically by GTK+.
  @end{short}

  In principle each widget in the chain should be a descendant of the
  @arg{container}, but this is not enforced by this method, since it is allowed
  to set the focus chain before you pack the widgets, or have a widget in the
  chain that is not always packed. The necessary checks are done when the focus
  chain is actually traversed."
  (container (g-object gtk-container))
  (focusable-widgets (g-list (g-object gtk-widget))))

(export 'gtk-container-set-focus-chain)

;;; ----------------------------------------------------------------------------
;;; gtk_container_unset_focus_chain ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_unset_focus_chain" gtk-container-unset-focus-chain)
    :void
 #+cl-cffi-gtk-documentation
 "@version{2013-3-10}
  @argument[container]{a @class{gtk-container} widget}
  @begin{short}
    Removes a focus chain explicitly set with 
    @fun{gtk-container-set-focus-chain}.
  @end{short}
  @see-function{gtk-container-set-focus-chain}"
  (container (g-object gtk-container)))

(export 'gtk-container-unset-focus-chain)

;;; ----------------------------------------------------------------------------
;;; gtk_container_class_find_child_property ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_class_find_child_property"
           gtk-container-class-find-child-property) :pointer
 #+cl-cffi-gtk-documentation
 "@version{2013-3-26}
  @argument[class]{a @class{gtk-container-class}}
  @argument[property-name]{the name of the child property to find}
  @begin{return}
    The @symbol{g-param-spec} of the child property or @code{nil} if @arg{class}
    has no child property with that name.
  @end{return}
  Finds a child property of a container class by name."
  (class :pointer)
  (property-name :string))

(export 'gtk-container-class-find-child-property)

;;; ----------------------------------------------------------------------------
;;; gtk_container_class_install_child_property ()
;;;
;;; void gtk_container_class_install_child_property (GtkContainerClass *cclass,
;;;                                                  guint property_id,
;;;                                                  GParamSpec *pspec);
;;;
;;; Installs a child property on a container class.
;;;
;;; cclass :
;;;     a GtkContainerClass
;;;
;;; property_id :
;;;     the id for the property
;;;
;;; pspec :
;;;     the GParamSpec for the property
;;; ----------------------------------------------------------------------------

;;; ----------------------------------------------------------------------------
;;; gtk_container_class_list_child_properties ()
;;; ----------------------------------------------------------------------------

(defcfun ("gtk_container_class_list_child_properties"
           gtk-container-class-list-child-properties)
    (:pointer (:pointer g-param-spec))
 #+cl-cffi-gtk-documentation
 "@version{2013-3-26}
  @argument[class]{a @class{gtk-container-class} object}
  @argument[n-properties]{location to return the number of child properties
    found}
  @return{A newly allocated list of @symbol{g-param-spec}.}
  Returns all child properties of a container class."
  (class (:pointer g-object-class))
  (n-properties (:pointer :int)))

(export 'gtk-container-class-list-child-properties)

;;; ----------------------------------------------------------------------------
;;; gtk_container_class_handle_border_width ()
;;;
;;; void gtk_container_class_handle_border_width (GtkContainerClass *klass);
;;;
;;; Modifies a subclass of GtkContainerClass to automatically add and remove the
;;; border-width setting on GtkContainer. This allows the subclass to ignore the
;;; border width in its size request and allocate methods. The intent is for a
;;; subclass to invoke this in its class_init function.
;;;
;;; gtk_container_class_handle_border_width() is necessary because it would
;;; break API too badly to make this behavior the default. So subclasses must
;;; "opt in" to the parent class handling border_width for them.
;;;
;;; klass :
;;;     the class struct of a GtkContainer subclass
;;; ----------------------------------------------------------------------------


;;; --- End of file gtk.container.lisp -----------------------------------------
