from flask import jsonify


def success_response(data=None, status_code=200):
    body = {"success": True}
    if data is not None:
        body["data"] = data
    return jsonify(body), status_code


def error_response(message, status_code=400):
    return jsonify({"success": False, "error": message}), status_code