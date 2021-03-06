Server
======

Server provide HTTP technologies integrations under a common interface. They
inherit from `GLib.Application`_, providing an optimal integration with the
host environment.

.. toctree::
    :caption: Table of Contents

    http
    cgi
    fastcgi
    scgi

General
-------

Basically, you have access to a `DBusConnection`_ to communicate with other
process and a `GLib.MainLoop`_ to process events and asynchronous work.

-  an application id to identify primary instance
-  ``startup`` signal emmited right after the registration
-  ``shutdown`` signal just before the server exits
-  a resource base path
-  ability to handle CLI arguments

.. _DBusConnection: http://valadoc.org/#!api=gio-2.0/GLib.DBusConnection
.. _GLib.MainLoop: http://valadoc.org/#!api=glib-2.0/GLib.MainLoop

DBus connection
---------------

`GLib.Application`_ will automatically register to the session DBus bus, making
IPC (Inter-Process Communication) an easy thing.

It can be used to expose runtime information such as a database connection
details or the amount of processing requests. See this `example of DBus server`_
for code examples.

.. _example of DBus server: https://wiki.gnome.org/Projects/Vala/DBusServerSample

This can be used to request services, communicate between your workers and
interact with the runtime.

.. code:: vala

    var connection = server.get_dbus_connection ()

    connection.call ()

.. _GLib.Application: http://valadoc.org/#!api=gio-2.0/GLib.Application

Options
-------

Each server implementation can optionally take arguments that parametrize its
runtime.

If you build your application in a main block, it will not be possible to
obtain the CLI arguments to parametrize the runtime. Instead, the code can be
written in a usual ``main`` function.

.. code:: vala

    public static int main (string[] args) {
        return new Server ("org.vsgi.App", (req, res) => {
            res.status = Soup.Status.OK;
            return res.body.write_all ("Hello world!".data, null);
        }).run (args);
    }

If you specify the ``--help`` flag, you can get more information on the
available options which vary from an implementation to another.

.. code:: bash

    build/examples/fastcgi --help

.. code:: bash

    Usage:
      fastcgi [OPTION...]

    Help Options:
      -h, --help                  Show help options
      --help-all                  Show all help options
      --help-gapplication         Show GApplication options

    Application Options:
      -s, --socket                path to the UNIX socket
      -p, --port                  TCP port on this host
      -f, --file-descriptor=0     file descriptor
      -b, --backlog=0             listen queue depth used in the listen() call

