SCGI
====

SCGI (Simple Common Gateway Interface) is a stream-based protocol that is
particularly simple to implement.

.. note::

    SCGI is the recommended implementation and should be used when available as
    it takes the best out of GIO asynchronous API.

The implementation uses a `GLib.SocketService`_ and processes multiple requests
using non-blocking I/O.

.. _GLib.SocketService: http://valadoc.org/#!api=gio-2.0/GLib.SocketService

Options
-------

+-----------------------+---------+-----------------------------------------------+
| Option                | Default | Description                                   |
+=======================+=========+===============================================+
| ``--any``             | none    | listen on any open TCP port                   |
+-----------------------+---------+-----------------------------------------------+
| ``--port``            | none    | listen on a TCP port from local interface     |
+-----------------------+---------+-----------------------------------------------+
| ``--file-descriptor`` | 0       | listen to the provided file descriptor        |
+-----------------------+---------+-----------------------------------------------+
| ``--backlog``         | 10      | connection queue depth in the ``listen`` call |
+-----------------------+---------+-----------------------------------------------+

