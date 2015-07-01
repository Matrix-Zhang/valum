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
using Soup;

/**
 * It provides similar APIs to {@link Soup.MultipartInputStream}.
 *
 * @since 0.3
 */
public class VSGI.MultipartInputStream : FilterInputStream {

	public MessageHeaders headers { construct; get; }

	public MultipartInputStream (MessageHeaders headers, InputStream base_stream) {
		Object (headers: headers, base_stream: base_stream);
	}

	/**
	 * Obtain the next part of the message.
	 *
	 * @param part_headers headers of the part
	 * @return a stream over the next part of null if none's available
	 */
	public InputStream? next_part (out MessageHeaders part_headers, Cancellable? cancellable = null) throws IOError {
		HashTable<string, string> @params;
		headers.get_content_type (out @params);

		var boundary = @params["boundary"];

		assert (@params.contains ("boundary"));

		var line_reader = new DataInputStream (base_stream);

		line_reader.newline_type = DataStreamNewlineType.CR_LF;

		do {
			var line = line_reader.read_line (null, cancellable);

			// end of input
			if (line == null)
				break;

			// closing frontier
			if (line == "--" + boundary + "--")
				break;

			// opening frontier
			if (line == "--" + boundary) {
				// consume current headers
				var headers = new StringBuilder ();

				do {
					var header_line = line_reader.read_line (null, cancellable);

					if (header_line == "")
						break; // empty line preceeding the body

					if (header_line == null)
						return null; // end of input..?

					headers.append (header_line + "\r\n");
				} while (true);

				headers_parse (headers.str, (int) headers.len, part_headers);

			}
		} while (true);

		return new BoundedInputStream (base_stream, headers.get_content_length ());
		return null; // end of input
	}

	public async InputStream? next_part_async (Cancellable? cancellable = null) {

	}

	public override ssize_t read (uint8[] buffer, Cancellable? cancellable = null) throws IOError {
		return base_stream.read (buffer, cancellable);
	}

	public override bool close (Cancellable? cancellable = null) throws IOError {
		return base_stream.close (cancellable);
	}
}
