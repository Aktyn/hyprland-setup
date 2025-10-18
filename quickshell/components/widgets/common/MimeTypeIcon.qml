import QtQuick

import "../../../common"

MaterialSymbol {
  property string mimeType: ""

  text: {
    if (!mimeType) {
      return "delete_sweep";
    }

    if (mimeType.startsWith("image/")) {
      return "image";
    } else if (mimeType.startsWith("video/")) {
      return "movie";
    } else if (mimeType.startsWith("audio/")) {
      return "audio_file";
    } else if (mimeType === "application/pdf") {
      return "picture_as_pdf";
    } else if (mimeType === "application/zip" || mimeType === "application/x-rar-compressed" || mimeType === "application/x-7z-compressed") {
      return "folder_zip";
    } else if (mimeType.startsWith("text/")) {
      return "description";
    } else if (mimeType.startsWith("inode/directory")) {
      return "folder_copy";
    } else {
      return "draft";
    }
  }
}
