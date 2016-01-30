/*
 * This file is part of Valum.
 *
 * Valum is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Valum is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Valum.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;

/**
 * Loader for VSGI-compliant application written as GModule.
 *
 * The only requirement is to provide a {@link VSGI.ApplicationCallback}
 * compatible symbol in the shared library.
 *
 * Only active implementations like {@link VSGI.Soup}, {@link VSGI.SCGI} and
 * {@link VSGI.FastCGI} are supported.
 *
 * @since 0.3
 */
namespace VSGI.Loader {

	/**
	 * @since 0.3
	 */
	public class ApplicationModule : Object {

		private Module? module = null;

		public string directory { construct; get; }

		public string filename { construct; get; }

		public string symbol { construct; get; }

		public ApplicationModule (string directory, string filename, string symbol) {
			Object (directory: directory, filename: filename, symbol: symbol);
		}

		public bool load () {
			var module_path = Module.build_path (directory, filename);
			module          = Module.open (module_path, ModuleFlags.BIND_LAZY);
			return module == null;
		}

		public void unload () {
			module = null;
		}

		public bool get_application_callback (out ApplicationCallback app) {
			void* app_symbol;

			if (!module.symbol (symbol, out app_symbol)) {
				stderr.printf ("%s\n", Module.error ());
				return false;
			}

			app = (ApplicationCallback) (owned) app_symbol;

			return true;
		}
	}

	/**
	 * @since 0.3
	 */
	public string? directory;

	/**
	 * @since 0.3
	 */
	public string server;

	/**
	 * @since 0.3
	 */
	public string? application_id;

	/**
	 * @since 0.3
	 */
	const OptionEntry[] options = {
		{"directory",      'd', 0, OptionArg.FILENAME, ref directory,      "the directory where MODULE is located"},
		{"server",         'i', 0, OptionArg.STRING,   ref server,         "technology used to serve the application", "http"},
		{"application-id", 'a', 0, OptionArg.STRING,   ref application_id, "application identifier"},
		{null}
	};

	public int main (string[] args) requires (Module.supported ()) {
		// default options
		directory      = null;
		server         = "http";
		application_id = null;

		try {
			var parser = new OptionContext ("MODULE:SYMBOL [-- SERVER_OPTION...]");
			parser.set_summary ("Load a VSGI application written as a GModule and serve it using a supported\n" +
					            "technology.\n" +
								"\n" +
								"Only active server technologies such as libsoup-2.4, FastCGI and SCGI are \n" +
								"supported for the '--server' option. They correspond to 'http', 'fastcgi' and\n" +
								"'scgi' values respectively.\n" +
								"\n" +
								"MODULE is the shared library name without the 'lib' prefix and extension and\n" +
								"SYMBOL identifies a symbol in the library respecting the 'ApplicationCallback'\n" +
								"signature.\n" +
								"\n" +
								"SERVER_OPTION is forwarded to the server and must be separated from other\n" +
								"arguments by a '--' delimiter.");
			parser.add_main_entries (options, null);
			parser.parse (ref args);
		} catch (OptionError err) {
			stderr.puts (err.message);
			return 1;
		}

		// count the remaining arguments once parsed
		if (args.length < 2) {
			stderr.printf ("module and symbol identifier are missing\n");
			return 1;
		}

		var module_and_symbol = args[1].split (":");

		if (module_and_symbol.length != 2) {
			stderr.printf ("'%s' is not a valid module and symbol identifier\n", args[1]);
			return 1;
		}

		var server_module = new ServerModule (server);

		if (!server_module.load ()) {
			stderr.printf ("%s\n", Module.error ());
			return 1;
		}

		var app_module = new ApplicationModule (directory, module_and_symbol[0], module_and_symbol[1]);

		if (!app_module.load ()) {
			stderr.printf ("%s\n", Module.error ());
			return 1;
		}

		// use the module:symbol as zeroth argument
		string[] server_args = {args[1]};

		// append args following the '--'
		if (args.length > 2 && args[2] == "--")
			foreach (var arg in args[3:args.length])
				server_args += arg;

		var svr = (Server) Object.@new (server_module.server_type, "application-id", application_id);

		ApplicationCallback app;
		if (!app_module.get_application_callback (out app)) {
			stderr.printf ("%s\n", Module.error ());
			return 1;
		}

		svr.set_application_callback ((owned) app);

		// reload the application in SIGHUP
		Unix.signal_add (ProcessSignal.HUP, () => {
			// serve a temporary app
			svr.set_application_callback ((req, res) => {
				res.status = 200;
				size_t bytes_written;
				res.body.write_all ("Reloading...".data, out bytes_written);
			});

			app_module.unload ();

			if (app_module.load () && app_module.get_application_callback (out app)) {
				svr.set_application_callback ((owned) app);
			} else {
				stderr.printf ("%s\n", Module.error ());
				svr.release ();
				return false;
			}

			return true;
		});

		return svr.run (server_args);
	}
}
