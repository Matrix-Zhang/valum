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

	/**
	 * Algorithms used for digest authentication.
	 *
	 * @since 0.3
	 */
	public enum AuthAlgorithm {
		MD5,
		MD5_SESS
	}

	/**
	 * @since 0.3
	 */
	[Flags]
	public enum AuthProtectionQuality {
		AUTH,
		AUTH_INT
	}

	/**
	 * Lookup the provided credentials against
	 *
	 * For a digest HTTP authentication, the secret_id is hashed according to
	 * RFC2617.
	 *
	 * [[https://tools.ietf.org/html/rfc2617]]
	 *
	 * @since 0.3
	 *
	 * @param client_id client identification if appliable
	 * @param secret_id secret against which we perform the authentication
	 *
	 * @return true if the secret_id authenticates the client_id
	 */
	public delegate bool AuthCallback (string client_id, string secret_id);

	/**
	 * Perform a basic HTTP authentication.
	 *
	 * If the client is authorized, the 'client_id' will be pushed on the stack
	 * for the next handler, state, otherwise a {@link Valum.ClientError.UNAUTHORIZED}
	 * will be thrown.
	 *
	 * @param auth_callback callback used to verify the credentials
	 * @param realm         realm for the authentication or none if 'null'
	 */
	public HandlerCallback authenticate_basic (AuthCallback auth_callback, string? realm = null) {
		return (req, res, next, stack) => {
			var authorization = req.headers.get_one ("Authorization");

			if (authorization != null) {
				var decoded = GLib.Base64.decode (authorization);
				var parts   = decoded.split (":", 1);
				if (parts.length == 2 && auth_callback (parts[0], parts[1])) {
					stack.push_tail (parts[0]);
					next (req, res);
					return;
				}
			}

			var auth_header = new StringBuilder ("Basic");

			if (realm != null) {
				auth_header.append_printf (" \"%s\"", realm);
			}

			throw new ClientError.UNAUTHORIZED (auth_header);
		};
	}

	/**
	 * Perform a digest HTTP authentication.
	 *
	 * If the client is authorized, next will be invoked with the 'client_id' as
	 * state, otherwise a {@link Valum.ClientError.UNAUTHORIZED} will be thrown.
	 *
	 * @since 0.3
	 *
	 * @param auth_callback callback used to perform the authentication
	 * @param secret        secret key used to generate the nonce and opaque
	 *                      tokens
	 * @param opaque        value expected to be provided by the client
	 * @param realm         realm for the authentication
	 * @param domains       domains that accepts the authentication
	 * @param algorithm     algorithm used
	 * @param qop           quality of protection
	 */
	public HandlerCallback authenticate_digest (AuthCallback          auth_callback,
												uint8[]               secret,
												uint8[]	              opaque,
	                                            string?               realm     = null,
	                                            string[]?             domains   = null,
	                                            AuthAlgorithm         algorithm = AuthAlgorithm.MD5,
	                                            AuthProtectionQuality qop       = AuthProtectionQuality.AUTH) {
		return (req, res, next) => {
			var authorization = req.headers.get_one ("Authorization");

			var auth_header = new StringBuilder ("Digest");

			if (realm != null) {
				auth_header.append_printf (" realm=\"%s\",", realm);
			}

			var nonce  = Hmac.compute_for_data (ChecksumType.SHA1, secret, unique.data);
			var opaque = Checksum.compute_for_data (ChecksumType.SHA1, opaque);
			var qop    = "auth,auth-int"; // todo..

			auth_header.append_printf ("nonce=\"%s\", opaque=\"%s\"", nonce, opaque);

			if (authorization != null) {
				var decoded = GLib.Base64.decode (authorization);
				var parts   = decoded.split (":", 1);
				if (parts.length == 2 && auth_callback (parts[0], parts[1])) {
					stack.push_tail (parts[0]);
					next (req, res);
					return;
				} else {
					// TODO: stale
					auth_header.append (", stale");
				}
			}

			auth_header.append ("algorithm=\"%s\"", algorithm == AuthAlgorithm.MD5_SESS ? "MD5-sess" : "MD5");

			auth_header.append_printf (", qop=\"%s\"", qop);

			throw new ClientError.UNAUTHORIZED (auth_header.str);
		};
	}
}
