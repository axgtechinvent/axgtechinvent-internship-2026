# Upload validation helpers

ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif", "pdf", "txt", "docx", "csv", "zip"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


def allowed_file(filename):
    # Return true if the filename has an allowed extension
    if "." not in filename:
        return False
    ext = filename.rsplit(".", 1)[1].lower()
    return ext in ALLOWED_EXTENSIONS


def validate_upload(file):
    # validate an uploaded file
    if file is None or file.filename == "":
        return False, "No file selected"

    if not allowed_file(file.filename):
        return False, f"File type not allowed. Allowed types: {', '.join(sorted(ALLOWED_EXTENSIONS))}"

    # determine file size without loading it fully into memory
    file.seek(0, 2)  # seek to end
    size = file.tell()
    file.seek(0)  # reset pointer for later use (upload)

    if size == 0:
        return False, "File is empty"

    if size > MAX_FILE_SIZE_BYTES:
        return False, f"File too large. Maximum size is {MAX_FILE_SIZE_BYTES // (1024*1024)}MB"

    return True, None