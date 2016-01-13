using GLib;

namespace VSGI {

	/**
	 * @since 0.3
	 */
	public class ServerModule : TypeModule {

		[CCode (has_target = false)]
		private delegate Type PluginInitFunc (TypeModule module);

		/**
		 * Name of the shared library holding the server implementation.
		 *
		 * @since 0.3
		 */
		public string name { construct; get; }

		/**
		 * Type of the {@link VSGI.Server} if this is loaded.
		 *
		 * @since 0.3
		 */
		public Type? server_type { get; private set; default = null; }

		/**
		 * @since 0.3
		 */
		public ServerModule (string name) {
			Object (name: name);
		}

		/**
		 *
		 */
		public override bool load () {
			var path   = Module.build_path (null, "vsgi-%s".printf (name));
			var module = Module.open (path, ModuleFlags.BIND_LAZY);

			if (null == module)
				return false;

			void* plugin_init;
			if (!module.symbol ("plugin_init", out plugin_init))
				return false;

			server_type = ((PluginInitFunc) plugin_init) (this);

			// never unload the server
			module.make_resident ();

			return true;
		}
	}
}
