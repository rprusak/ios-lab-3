//
//  FilesDownloadController.swift
//  lab3_ams
//
//  Created by r on 13/01/2018.
//  Copyright © 2018 r. All rights reserved.
//

import UIKit

class FilesDownloadController: UITableViewController, URLSessionDownloadDelegate {
    
    var downloads: Array<DownloadStatus> = []
    var destinationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    var backgroundQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).backgroundQueue")
    let startTime = NSDate();
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let urlString = downloadTask.originalRequest!.url!.absoluteString
        
        for i in 0..<downloads.count {
            if self.downloads[i].fileUrl == urlString {
                
                let now = NSDate()
                let diff = now.timeIntervalSince(startTime as Date)
                print("\(diff) file \(i + 1) downloaded, temporary path: \(location.absoluteString)")
                
                self.downloads[i].imageUrl = destinationDirectory + "/\(i).jpg"
                self.downloads[i].completed = true
                self.copyImage(from: location, to: URL(fileURLWithPath: destinationDirectory + "/\(i).jpg"), i);
                self.detectFace(index: i)
                self.tableView.reloadData()
                break;
            }
        }
    }
    
    func copyImage(from: URL, to: URL, _ index: Int) {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: to.absoluteString) {
            if (try? fileManager.removeItem(at: to)) != nil {
                //print("removed file \(to.absoluteString)")
            } else {
                //print("error removing file \(to.absoluteString)")
            }
        } else {
            //print("file \(to.absoluteString) does not exits")
        }
        
        if (try? fileManager.copyItem(at: from, to: to)) != nil {
            //print("sucessfully copied file from \(from.absoluteString) to \(to.absoluteString)")
        } else {
            //print("error while coping file from \(from.absoluteString) to \(to.absoluteString)")
        }
        
        let now = NSDate()
        let diff = now.timeIntervalSince(startTime as Date)
        print("\(diff) file \(index + 1) copied to \(to.absoluteString)")
    }
    
    
    func detectFace(index: Int){
        self.backgroundQueue.async{
            let now = NSDate()
            let diff = now.timeIntervalSince(self.startTime as Date)
            print("\(diff) face detection on image \(index + 1) started")
            
            let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let imagePath = self.downloads[index].imageUrl
            let coreImage = CIImage(contentsOf: URL(fileURLWithPath: imagePath))!
            let features = faceDetector.features(in: coreImage)
            
            let now2 = NSDate()
            let diff2 = now2.timeIntervalSince(self.startTime as Date)
            print("\(diff2) face detection on image \(index + 1) compleated, faces datected: \(features.count)")
            
            self.downloads[index].numberOfFaces = features.count
            self.downloads[index].faceDetected = true
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let urlString = downloadTask.originalRequest!.url!.absoluteString
        let progress = (totalBytesWritten*100)/totalBytesExpectedToWrite
        for i in 0..<downloads.count {
            if self.downloads[i].fileUrl == urlString {
                self.downloads[i].progress = Int(progress)
                
                if progress == 50 {
                    let now = NSDate()
                    let diff = now.timeIntervalSince(self.startTime as Date)
                    print("\(diff) 50% progress on image \(i + 1)")
                }
                
                self.tableView.reloadData()
                break;
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startDownload();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func startDownload() {
        for (index, image) in IMAGES.enumerated() {
            self.downloads.append(DownloadStatus(fileUrl: image, completed: false, progress: 0, imageUrl: "", faceDetected: false, numberOfFaces: 0))
            self.tableView.reloadData()
            self.startDownloadingFile(index, image)
        }
    }
    
    func startDownloadingFile(_ index: Int, _ file: String) {
        let now = NSDate()
        let diff = now.timeIntervalSince(self.startTime as Date)
        
        print("\(diff) start download file \(index + 1) \(file)")
        let imageURL:URL = URL(string: file)!
        let config = URLSessionConfiguration.background(withIdentifier: "pl.edu.agh.kis.bgDownload" + String(index + 1))
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.downloadTask(with: imageURL)
        task.resume()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloads.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
        let status = self.downloads[indexPath.row]
        
        cell.textLabel?.text = "\(status.fileUrl)"
        
        if status.completed {
            cell.detailTextLabel?.text = "Download done."
            cell.imageView?.image = UIImage(contentsOfFile: status.imageUrl)
            if status.faceDetected {
                if status.numberOfFaces > 0 {
                    cell.detailTextLabel?.text = (cell.detailTextLabel?.text)! + " Found \(status.numberOfFaces) faces"
                } else {
                    cell.detailTextLabel?.text = (cell.detailTextLabel?.text)! + " Found no face"
                }
            } else {
                cell.detailTextLabel?.text = (cell.detailTextLabel?.text)! + " Detecting face...."
            }
        } else {
            cell.detailTextLabel?.text = "Downloading, progress \(status.progress)%."
        }
        
        return cell
    }
 
}
