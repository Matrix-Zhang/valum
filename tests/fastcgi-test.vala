using VSGI.FastCGI;

/**
 * @since 0.2
 */
public static void test_vsgi_fastcgi_request () {
	var environment   = new HashTable<string, string> (str_hash, str_equal);

	environment["PATH_INFO"]      = "/";
	environment["REQUEST_METHOD"] = "GET";
	environment["REQUEST_URI"]    = "/";
	environment["SERVER_NAME"]    = "0.0.0.0";
	environment["SERVER_PORT"]    = "3003";
	environment["HTTP_HOST"]      = "example.com";

	var connection = new VSGI.Test.Connection ();
	var request    = new Request (connection, environment);

	assert (Soup.HTTPVersion.@1_0 == request.http_version);
	assert ("GET" == request.method);
	assert ("0.0.0.0" == request.uri.get_host ());
	assert (3003 == request.uri.get_port ());
	assert (null == request.query);
	assert (null == request.params);
	assert ("example.com" == request.headers.get_one ("Host"));
	assert (connection.input_stream == request.body);
}

/**
 * @since 0.2
 */
public static void test_vsgi_fastcgi_request_https_on () {
	var environment   = new HashTable<string, string> (str_hash, str_equal);

	environment["PATH_INFO"]      = "/";
	environment["REQUEST_METHOD"] = "GET";
	environment["REQUEST_URI"]    = "/";
	environment["SERVER_NAME"]    = "0.0.0.0";
	environment["SERVER_PORT"]    = "3003";

	environment["HTTPS"] = "on";

	var connection = new VSGI.Test.Connection ();
	var request    = new Request (connection, environment);

	assert ("https" == request.uri.scheme);
}

/**
 * @since 0.2
 */
public static void test_vsgi_fastcgi_request_uri_with_query () {
	var environment   = new HashTable<string, string> (str_hash, str_equal);

	environment["PATH_INFO"]      = "/";
	environment["REQUEST_METHOD"] = "GET";
	environment["REQUEST_URI"]    = "/";
	environment["SERVER_NAME"]    = "0.0.0.0";
	environment["SERVER_PORT"]    = "3003";

	environment["REQUEST_URI"] = "/home?a=b";

	var connection = new VSGI.Test.Connection ();
	var request    = new Request (connection, environment);

	assert ("/home" == request.uri.path);
}

/**
 * @since 0.2
 */
public static void test_vsgi_fastcgi_response () {
	var environment   = new HashTable<string, string?> (str_hash, str_equal);

	environment["PATH_INFO"]      = "/";
	environment["REQUEST_METHOD"] = "GET";
	environment["REQUEST_URI"]    = "/";
	environment["SERVER_NAME"]    = "0.0.0.0";
	environment["SERVER_PORT"]    = "3003";

	var connection = new VSGI.Test.Connection ();
	var request    = new Request (connection, environment);
	var response   = new Response (request);

	assert (request == response.request);
	assert (!response.head_written);
	assert (connection.output_stream == response.body);
}