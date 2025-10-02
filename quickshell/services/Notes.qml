pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import "../common"

/**
 * Notes storage service.
 * Supports multiple notes, each stored in its own file, and manages
 * an index file listing notes (name + file path).
 * Keeps legacy single-note API for compatibility.
 */
Singleton {
  id: root

  // Legacy single-note path (kept for compatibility / migration)
  property string filePath: Utils.trimFileProtocol(`${Consts.path.cache}/notes.txt`)
  property string text: ""

  // Index file listing all notes
  property string indexPath: Utils.trimFileProtocol(`${Consts.path.cache}/notes_index.json`)

  // Expose the ListModel to UI
  property alias notesModel: notesListModel

  function setText(newText) {
    // Legacy setter (unused by new UI)
    root.text = newText ?? "";
    notesFileView.setText(root.text);
  }

  function refresh() {
    // Legacy refresh
    notesFileView.reload();
  }

  function loadIndex() {
    indexFileView.reload();
  }

  function persistIndex() {
    const arr = [];
    for (let i = 0; i < notesListModel.count; i++) {
      const it = notesListModel.get(i);
      arr.push({
        name: it.name,
        file: it.file
      });
    }
    indexFileView.setText(JSON.stringify(arr, null, 2));
  }

  function addNote() {
    const idx = notesListModel.count + 1;
    const name = `Note ${idx}`;
    const unique = Date.now();
    const file = Utils.trimFileProtocol(`${Consts.path.cache}/note_${unique}.txt`);
    notesListModel.append({
      name: name,
      file: file
    });
    persistIndex();
  }

  function removeNote(index) {
    if (index >= 0 && index < notesListModel.count) {
      notesListModel.remove(index);
      persistIndex();
    }
  }

  Component.onCompleted: {
    // Load index and legacy note content
    loadIndex();
    refresh();

    //TODO: remove non indexed notes that are older than N days
    console.log(root.filePath, root.indexPath);
  }

  // Model holding notes entries
  ListModel {
    id: notesListModel
  }

  // Index file IO
  FileView {
    id: indexFileView
    path: root.indexPath
    onLoaded: {
      try {
        const raw = indexFileView.text() || "[]";
        const data = JSON.parse(raw);
        notesListModel.clear();
        for (let i = 0; i < data.length; i++) {
          const entry = data[i] || {};
          const name = entry.name || `Note ${i + 1}`;
          const file = Utils.trimFileProtocol(entry.file || "");
          if (file)
            notesListModel.append({
              name: name,
              file: file
            });
        }
        // If index existed but was empty, fall back to default
        if (notesListModel.count === 0) {
          const defFile = root.filePath;
          notesListModel.append({
            name: "Note 1",
            file: defFile
          });
          root.persistIndex();
        }
        console.log("[Notes] Index file loaded");
      } catch (e) {
        console.log("[Notes] Failed to parse index file, resetting: " + e);
        notesListModel.clear();
        const defFile = root.filePath;
        notesListModel.append({
          name: "Note 1",
          file: defFile
        });
        root.persistIndex();
      }
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        console.log("[Notes] Index file not found, creating a default one.");
        notesListModel.clear();
        const defFile = root.filePath;
        notesListModel.append({
          name: "Note 1",
          file: defFile
        });
        root.persistIndex();
      } else {
        console.log("[Notes] Error loading index file: " + error);
      }
    }
  }

  // Legacy single-note file IO
  FileView {
    id: notesFileView
    path: root.filePath
    onLoaded: {
      const fileContents = notesFileView.text();
      root.text = fileContents;
      console.log("[Notes] Legacy file loaded");
    }
    onLoadFailed: error => {
      if (error == FileViewError.FileNotFound) {
        console.log("[Notes] Legacy file not found, creating new file.");
        root.text = "";
        notesFileView.setText(root.text);
      } else {
        console.log("[Notes] Error loading legacy file: " + error);
      }
    }
  }
}
