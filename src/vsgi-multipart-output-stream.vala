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
 * Stream designed to produce multipart MIME messages.
 *
 * To create a part, {@link VSGI.MultipartOutputStream.new_part} has to be
 * called. The actual part body must be written directly in the stream.
 *
 * @since 0.3
 */
public class MultipartOutputStream : FilterOutputStream {

	public MessageHeaders headers { construct; get; }

	public MultipartOutputStream (MessageHeaders headers, OutputStream base_stream) {
		Object (headers: headers, base_stream: base_stream);
	}

	private uint8[] build_part (MessageHeaders part_headers) {
		HashTable<string, string> @params;
		headers.get_content_type (out @params);

		var boundary = @params["boundary"];
		var writer   = new DataOutputStream (base_stream);

		var part = new StringBuilder ("");

		part.append_printf ("--%s\r\n", boundary);

		part_headers.foreach ((k, v) => {
			part.append_printf ("%s: %s\r\n", k, v);
		});

		part.append ("\r\n");

		return part.str.data;
	}

	/**
	 * Create a new part in this multipart message.
	 *
	 * The opening boundary and headers are written in the base stream,
	 * preparing the land for the body to be written.
	 *
	 * @since 0.3
	 */
	public bool new_part (MessageHeaders part_headers) throws IOError {
		return base_stream.write_all (build_part (part_headers), null);
	}

	/**
	 * @see VSGI.MultipartOutputStream.new_part
	 *
	 * @since 0.3
	 */
	public bool new_part_async (MessageHeaders part_headers) throws IOError {
		return yield base_stream.write_all_async (part.str.data)
	}

	public override ssize_t write (uint8[] buffer, Cancellable? cancellable = null) throws IOError {
		return base_stream.write (buffer, cancellable);
	}

	/**
	 * Append the final enclosing boundary and close the base stream.
	 */
	public override bool close (Cancellable? cancellable = null) throws IOError {
		HashTable<string, string> @params;
		headers.get_content_type (out @params);

		var boundary = @params["boundary"];
		var writer   = new DataOutputStream (base_stream);

		return writer.put_string ("--" + boundary + "--\r\n", cancellable) && base_stream.close (cancellable);
	}
}
