//
//  File.swift
//  lab3_ams
//
//  Created by r on 13/01/2018.
//  Copyright © 2018 r. All rights reserved.
//

import Foundation

struct DownloadStatus {
    var fileUrl: String;
    var completed: Bool;
    var progress: Int;
    var imageUrl: String;
    var faceDetected: Bool;
    var numberOfFaces: Int;
}
