/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SQLite3
import PlaygroundSupport

destroyPart1Database()

/*:
 
 # Getting Started
 
 The first thing to do is set your playground to run manually rather than automatically. This will help ensure that your SQL commands run when you intend them to. At the bottom of the playground click and hold the Play button until the dropdown menu appears. Choose "Manually Run".
 
 You will also notice a `destroyPart1Database()` call at the top of this page. You can safely ignore this, the database file used is destroyed each time the playground is run to ensure all statements execute successfully as you iterate through the tutorial.
 
 */


//: ## Open a Connection
func openDatabase() -> OpaquePointer? {
    var db: OpaquePointer?
    guard let part1DbPath = part1DbPath else {
        print("part1DbPath is nil")
        return nil
    }
    if sqlite3_open(part1DbPath, &db) == SQLITE_OK {
        print("Successfully opened connection to database at \(part1DbPath)")
        return db
    } else {
        print("Unable to open database")
        PlaygroundPage.current.finishExecution()
    }
}

let db = openDatabase()

// TABLE CREATION: create a table

// SQL statement
let createTableString = """
CREATE TABLE Contact(
Id INT PRIMARY KEY NOT NULL,
Name CHAR(255)
);
"""

// method to create a table
func createTable() {
    //1
    var createTableStatement: OpaquePointer?
    //2
    if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
        //3
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
            print("\nContact table created.")
        } else {
            print("\nContect table is not created.")
        }
    } else {
        print("\nCREATE TABLE statement is not prepared")
    }
    //4
    sqlite3_finalize(createTableStatement)
}

// FUNCTION: function call
createTable()
//: ## Insert a Contact
let insertStatementString = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"

func insert() {
    var insertStatement: OpaquePointer?
    //1
    // compile the state, check if all is well
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
        let id: Int32 = 1
        let name: NSString = "Steve"
        //2
        // define a value for the ? place holder, function to bind an int to the statement
        // parameters (statement to bind to, index for (?, ?), value) -> a status code
        sqlite3_bind_int(insertStatement, 1, id)
        //3
        // parameters (statement to bind to, index for (?, ?), value, ?, ?) -> a status code
        sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
        //4
        // function to execute the statement, verify that it is finished
        if sqlite3_step(insertStatement) == SQLITE_DONE {
            print("Successfully inserted row.")
        } else {
            print("\nFailed to insert row.")
        }
    } else {
        print("\nINSERT statement is not prepared.")
    }
    
    //5
    // finalise the statement, to insert multiple contacts retain the statement then reuse it with different values
    sqlite3_finalize(insertStatement)
}

insert()
//: ## Challenge - Multiple Inserts
func insertMultipleContacts() {
    
    var insertStatement: OpaquePointer?
    
    let names : [NSString] = ["Alan", "Bill", "Albert", "Abraham"]
    
    //1
    if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
        //2
        print("\n")
        for (index,name) in names.enumerated() {
            //3
            let id = Int32(index + 2) // originally Int32(index + 1)
            sqlite3_bind_int(insertStatement, 1, id)
            sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("\nFailed to insert row.")
            }
            //4
            sqlite3_reset(insertStatement)
        }
        sqlite3_finalize(insertStatement)
    } else {
        print("\nINSERT statement is not prepared.")
    }
}

insertMultipleContacts()
//: ## Querying
// * returns all columns
let queryStatementString = "SELECT * FROM Contact;"

func query() {
    
    var queryStatement: OpaquePointer?
    //1
    // prepare the statement
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        //2
        // retrieving the status code sqlite_row
        if sqlite3_step(queryStatement) == SQLITE_ROW {
            //3
            // read the values from the return row, access the row's values column by column
            // access the int value of id, and a zero based column index
            let id = sqlite3_column_int(queryStatement, 0)
            //4
            // access the text value of name, and a zero based column index
            // retrieve c api query result then convert it to string
            let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            let name = String(cString: queryResultCol1!)
            //5
            // print the results
            print("\nQuery Result:")
            print("\(id) | \(name)")
        } else {
            print("\nQuery returned no results.")
        }
    } else {
        //6
        // print errors if any
        let errorMessage = String(cString: sqlite3_errmsg(db))
        print("\nQuery could not be prepared! \(errorMessage)")
    }
    //7
    // finanlise the statement
    sqlite3_finalize(queryStatement)
}

query()
//: ## Challenge - Querying multiple rows
func queryMultipleContacts() {
    
    var queryStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
        print("\n")
        // while loop which will execute the step, this is true as long as the return code is sqlite_row,
        // reaching the last row return sqlite_done
        while (sqlite3_step(queryStatement) == SQLITE_ROW) {
            let id = sqlite3_column_int(queryStatement, 0)
            
            let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
            let name = String(cString: queryResultCol1!)
            
            print("Query Result:")
            print("\(id) | \(name)")
        }
    } else {
        let errorMessage = String(cString: sqlite3_errmsg(db))
        print("\nQuery could not be prepared! \(errorMessage)")
    }
    sqlite3_finalize(queryStatement)
}

queryMultipleContacts()
//: ## Update
let updateStatementString = "UPDATE Contact SET Name = 'Steve' WHERE Id = 1;"

func update() {
    var updateStatement: OpaquePointer?
    if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
        if sqlite3_step(updateStatement) == SQLITE_DONE {
            print("\nSuccessfully updated row.")
        } else {
            print("\nFailed to update row.")
        }
    } else {
        print("\nUPDATE statement is not prepared")
    }
    sqlite3_finalize(updateStatement)
}

update()
query()
//: ## Delete
let deleteStatementString = "DELETE FROM Contact WHERE Id = 1;"

func delete() {
    
    var deleteStatement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
            print("Successfully deleted row.")
        } else {
            print("\nFailed to delete row.")
        }
    } else {
        print("\nDELETE statement could not be prepared")
    }
    sqlite3_finalize(deleteStatement)
}

//delete()
//query()



// ERROR HANDLING : handling errors

let malformedQueryString = "SELECT Stuff from Things WHERE Whatever;"

func prepareMalFormedQuery() {
    
    var malformedStatement: OpaquePointer?
    
    //1
    // force an error, statement will fail and return an error
    if sqlite3_prepare_v2(db, malformedQueryString, -1, &malformedStatement, nil) == SQLITE_OK {
        print("\nThis should not have happened")
    } else {
        //2
        // get the error message from the database, returns a textual description of the most recent error
        let errorMessage = String(cString: sqlite3_errmsg(db))
        print("\nQuery is not prepared! \(errorMessage)")
    }
    
    //3
    // finalise the statement
    sqlite3_finalize(malformedStatement)
}

prepareMalFormedQuery()
//: ## Close the database connection
sqlite3_close(db)
//: Continue to [Making It Swift](@next)

