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
using VSGI;

namespace Valum {

	public enum DecodeFlags {
		/**
		 * @since 0.3
		 */
		NONE,
		/**
		 * Forward with the remaining content encodings if they are expected to
		 * be processed later.
		 *
		 * @since 0.3
		 */
		FORWARD_REMAINING_ENCODINGS
	}

	/**
	 * Decode any applied 'Content-Encoding'.
	 *
	 * Supports 'gzip', 'deflate' and 'identity', otherwise raise a
	 * {@link Valum.ServerError.NOT_IMPLEMENTED}.
	 *
	 * @since 0.3
	 */
	public HandlerCallback decode (DecodeFlags flags = DecodeFlags.NONE) {
		return (req, res, next, ctx) => {
			var encodings = Soup.header_parse_list (req.headers.get_list ("Content-Encoding") ?? "");

			// decode is in the opposite order of application
			encodings.reverse ();

			req.headers.remove ("Content-Encoding");

			// placeholder
			var _req = req;

			for (unowned SList<string> encoding = encodings; encoding != null; encoding = encoding.next) {
				switch (encoding.data.down ()) {
					case "gzip":
						_req = new ConvertedRequest (_req, new ZlibDecompressor (ZlibCompressorFormat.GZIP));
						_req.headers.set_encoding (Soup.Encoding.EOF);
						break;
					case "deflate":
						_req = new ConvertedRequest (_req, new ZlibDecompressor (ZlibCompressorFormat.RAW));
						_req.headers.set_encoding (Soup.Encoding.EOF);
						break;
					case "identity":
						// nothing to do, let's take a break ;)
						break;
					default:
						if (DecodeFlags.FORWARD_REMAINING_ENCODINGS in flags) {
							// reapply remaining encodings
							encoding.reverse ();
							foreach (var remaining in encoding) {
								message (remaining);
								_req.headers.append ("Content-Encoding", remaining);
							}
							next (_req, res);
							return;
						} else {
							throw new ServerError.NOT_IMPLEMENTED ("The '%s' encoding is not understandable.",
							                                       encoding.data);
						}
				}
			}

			next (_req, res);
		};
	}

	/**
	 * Decode the request content charset to the desired one.
	 *
	 * @since 0.3
	 *
	 * @param destination destination charset
	 */
	public HandlerCallback decode_charset (string destination, DecodeFlags flags = DecodeFlags.NONE) {
		return (req, res, next) => {
			HashTable<string, string> @params;
			var content_type = req.headers.get_content_type (out @params);
			var from         = @params["charset"];

			// no charset to decode (or default)
			if (from == null) {
				next (req, res);
				return;
			}

			// identity
			if (Soup.str_case_equal (from, destination)) {
				next (req, res);
				return;
			}

			CharsetConverter converter;
			try {
				converter = new CharsetConverter (destination, from);
			} catch (Error err) {
				if (DecodeFlags.FORWARD_REMAINING_ENCODINGS in flags) {
					next (req, res);
					return;
				} else {
					throw new ServerError.NOT_IMPLEMENTED ("%s.", err.message);
				}
			}

			// transparently indicate the conversion
			@params["charset"] = destination;
			req.headers.set_content_type (content_type, @params);
			next (new ConvertedRequest (req, converter), res);
		};
	}
}
