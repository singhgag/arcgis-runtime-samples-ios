//
// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit
import ArcGIS

class VectorTileCustomStyleViewController: UIViewController, VectorStylesVCDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap()
        }
    }
    @IBOutlet var changeStyleBarItem: UIBarButtonItem!
    // Array of the item IDs.
    private let itemIDs = ["1349bfa0ed08485d8a92c442a3850b06",
                           "bd8ac41667014d98b933e97713ba8377",
                           "02f85ec376084c508b9c8e5a311724fa",
                           "1bf0cc4a4380468fbbff107e100f65a5",
                           "9a01f41307ec4add9121a40cf020a6b6",
                           "ce8a34e5d4ca4fa193a097511daa8855"]
    // The item ID of the shown layer.
    var shownItemID: String?
    // The job to export the item resource cache.
    var exportVectorTilesJob: AGSExportVectorTilesJob?
    // The vector tiled layer created by the local VTPK and day custom style.
    var dayVectorTiledLayer: AGSArcGISVectorTiledLayer?
    // The vector tiled layer created by the local VTPK and night custom style.
    var nightVectorTiledLayer: AGSArcGISVectorTiledLayer?
    
    func getTemporaryURL() -> URL {
        // Get a suitable directory to place files.
        let directoryURL = FileManager.default.temporaryDirectory
        // Create a unique name for the item resource cache based on current timestamp.
        let temporaryFileName = UUID().uuidString
        // Create and return the full, unique URL.
        return directoryURL.appendingPathComponent("\(temporaryFileName)")
    }
    func loadVectorTiledLayer(url vectorTiledLayerURL: URL) -> AGSArcGISVectorTiledLayer {
        var offlineVectorTiledLayer: AGSArcGISVectorTiledLayer?
        // Get a temporary URL to download the custom style.
        let temporaryURL = getTemporaryURL()
        // Create a vector tile cache using the local vector tile package.
        let vectorTileCache = AGSVectorTileCache(name: "PSCC_vector")
        // Create a portal item with the URL.
        let portalItem = AGSPortalItem(url: vectorTiledLayerURL)!
        // Create a task to export the custom style resources.
        let task = AGSExportVectorTilesTask(portalItem: portalItem)
        // Get the AGSExportVectorTilesJob.
        exportVectorTilesJob = task.exportStyleResourceCacheJob(withDownloadDirectory: temporaryURL)
        // Start the job.
        exportVectorTilesJob?.start(statusHandler: nil) { [weak self] (result, error) in
            guard let self = self else { return }
            if let result = result {
                // Get the item resource cache from the result.
                let itemresourceCahce = result.itemResourceCache
                // Create a vector tiled layer with the vector tiled cache and the item resource cache.
                offlineVectorTiledLayer = AGSArcGISVectorTiledLayer(vectorTileCache: vectorTileCache, itemResourceCache: itemresourceCahce)
            } else if let error = error {
                // Handle errors.
                self.presentAlert(error: error)
            }
        }
//        try? FileManager.default.removeItem(at: temporaryURL)
        return offlineVectorTiledLayer!
    }
    
    private func showSelectedItem(_ itemID: String) {
        guard let map = mapView.map else { return }
        shownItemID = itemID
        // Set the viewpoint to display Dodge City, KS.
        let point = AGSPoint(x: -100.01766, y: 37.76528, spatialReference: .wgs84())
        mapView.setViewpoint(AGSViewpoint(center: point, scale: 5_000))
        if itemID == "9a01f41307ec4add9121a40cf020a6b6" {
            // If the custom day style is chosen, assign the local vector tile package to the basemap.
            map.basemap = AGSBasemap(baseLayer: dayVectorTiledLayer!)
        } else if itemID == "ce8a34e5d4ca4fa193a097511daa8855"{
            // If the custom night style is chosen, assign the local vector tile package to the basemap.
            map.basemap = AGSBasemap(baseLayer: nightVectorTiledLayer!)
        } else {
            // Get the vector tiled layer URL.
            let vectorTiledLayerURL = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=\(itemID)")!
            // Create a vector tiled layer from the URL.
            let vectorTiledLayer = AGSArcGISVectorTiledLayer(url: vectorTiledLayerURL)
            map.basemap = AGSBasemap(baseLayer: vectorTiledLayer)
            // Set the viewpoint.
            let centerPoint = AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: .webMercator())
            mapView.setViewpoint(AGSViewpoint(center: centerPoint, scale: 88659253.829259947))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load the offline vector tiled layers.
        dayVectorTiledLayer = loadVectorTiledLayer(url: URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=9a01f41307ec4add9121a40cf020a6b6")!)
        nightVectorTiledLayer = loadVectorTiledLayer(url: URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=ce8a34e5d4ca4fa193a097511daa8855")!)
        // Show the default vector tiled layer.
        showSelectedItem(itemIDs.first!)
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileCustomStyleViewController", "VectorStylesViewController"]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? VectorStylesViewController {
            controller.delegate = self
            controller.itemIDs = itemIDs
            controller.selectedItemID = shownItemID
            // Popover presentation logic.
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 220)
        }
    }
    
    // MARK: - VectorStylesVCDelegate
    
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String) {
        // Show newly the selected vector layer.
        showSelectedItem(itemID)
    }
}

extension VectorTileCustomStyleViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
