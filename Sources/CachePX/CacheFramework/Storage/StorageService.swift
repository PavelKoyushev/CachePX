import Foundation
import SQLite3

public actor StorageService {
    
    public static let shared = StorageService()
    
    private init() {}
    
    private var db: OpaquePointer?
    
    deinit {
        sqlite3_close(db)
    }
}

extension StorageService {
    
    nonisolated
    public func setup() {
        Task(priority: .userInitiated) {
            await openDatabase()
            await createTable()
        }
    }
    
    private func openDatabase() {
        let directoryURL = DirectoryManager.shared.dataBaseURL
            .appendingPathComponent("images.sqlite")
        
        if sqlite3_open(directoryURL.path, &db) != SQLITE_OK {
            Logger.shared.logEvent("❌ Error while opening database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            Logger.shared.logEvent("✅ Database successfully opened at path: \(directoryURL.path)")
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT UNIQUE,
            etag TEXT,
            lastModified TEXT,
            localPath TEXT
        );
        """
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            Logger.shared.logEvent("❌ Failed to create table: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
}

extension StorageService {
    
    public func closeDatabase() {
        if let db = db {
            if sqlite3_close(db) != SQLITE_OK {
                Logger.shared.logEvent("❌ Failed to close database connection: \(String(cString: sqlite3_errmsg(db)))")
            } else {
                Logger.shared.logEvent("✅ Database connection successfully closed")
            }
            self.db = nil
        }
    }
}


extension StorageService {
    
    func imageExists(url: String) -> Bool {
        
        let query = "SELECT 1 FROM Images WHERE url = ? LIMIT 1;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (url as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getDateForImage(with url: String) -> ImageCacheMetadata? {
        var result: ImageCacheMetadata?
        
        let query = "SELECT etag, lastModified, localPath FROM Images WHERE url = ? LIMIT 1;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (url as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                result = ImageCacheMetadata(etag: String(cString: sqlite3_column_text(statement, 0)),
                                            lastModified: String(cString: sqlite3_column_text(statement, 1)),
                                            localPath: String(cString: sqlite3_column_text(statement, 2)))
            }
        } else {
            Logger.shared.logEvent("❌ Failed to retrieve metadata: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_finalize(statement)
        
        return result
    }
    
    func insertImage(url: String, etag: String, lastModified: String, localPath: String) {
        
        let query = "INSERT OR IGNORE INTO Images (url, etag, lastModified, localPath) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (url as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (etag as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (lastModified as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (localPath as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                Logger.shared.logEvent("❌ Failed to insert image: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        
        sqlite3_finalize(statement)
    }
    
    func upsertImage(url: String, etag: String, lastModified: String, localPath: String) {
        
        let query = """
            INSERT INTO Images (url, etag, lastModified, localPath)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(url) DO UPDATE SET
                etag = excluded.etag,
                lastModified = excluded.lastModified,
                localPath = excluded.localPath
            WHERE Images.etag != excluded.etag OR Images.lastModified != excluded.lastModified;
            """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (url as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (etag as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, (lastModified as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, (localPath as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                Logger.shared.logEvent("❌ Error Upsert: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            Logger.shared.logEvent("❌ Failed to prepare Upsert query: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_finalize(statement)
    }
    
    func resetImagesTable() {
        
        let drop = "DROP TABLE IF EXISTS Images;"
        let create = """
            CREATE TABLE IF NOT EXISTS Images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT UNIQUE,
                etag TEXT,
                lastModified TEXT,
                localPath TEXT
            );
            """
        
        if sqlite3_exec(db, drop, nil, nil, nil) != SQLITE_OK {
            Logger.shared.logEvent("❌ Failed to delete table: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        if sqlite3_exec(db, create, nil, nil, nil) != SQLITE_OK {
            Logger.shared.logEvent("❌ Failed to create table: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            Logger.shared.logEvent("Images table reset successfully")
        }
    }
}
