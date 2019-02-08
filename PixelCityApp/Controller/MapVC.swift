import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController,UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUPViewHeightConstraint: NSLayoutConstraint!
    var spinner: UIActivityIndicatorView?
    var progressLable: UILabel?
    var locationManager = CLLocationManager()
    var screenSize = UIScreen.main.bounds
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    // to enable me to get my location
    var authorizationStatus = CLLocationManager.authorizationStatus()
    // to enable me at firs time getstatus of my location
    let regionRadius :Double = 1000 // the region  can i zoomin in it
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTab()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        collectionView?.isScrollEnabled = true
        pullUpView.addSubview(collectionView!)

        
    }
   
    func addDoubleTab(){
        /*to enable me to draw any pinmaek at any loaction on my map if i pressed double click on my map but mast import UITapGestureRecognizer protocol to do it */
        let doubleTab = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTab.numberOfTapsRequired = 2
        doubleTab.delegate = self
        mapView.addGestureRecognizer(doubleTab)
    }
    
    // if user wan't to cancel downloading image move view down and cancel process
    func addSwipe(){
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    // height of view that include collectionview
    func animateViewUp(){
        pullUPViewHeightConstraint.constant = 250
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown(){
        cancelAllSessions()
        pullUPViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    func addSpinner(){
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 120)
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
        
    }
    func removeSpinner(){
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    func addProgressLable(){
        progressLable = UILabel()
        progressLable?.frame = CGRect(x: (screenSize.width / 2) - 100 , y: 130, width: 200, height: 40)
        progressLable?.font = UIFont(name: "Avenir Next", size: 12)
        progressLable?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLable?.textAlignment = .center
        collectionView?.addSubview(progressLable!)
    }
    func removeProgressLable(){
        if progressLable != nil {
            progressLable?.removeFromSuperview()
        }
    }
    @IBAction func CenterMapBtnWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            CenterMapOnUserLocation()
            /*  if pressed on this button retun me back to center  region  of my map at any time */
        }
    }
    
}
extension MapVC: MKMapViewDelegate {
    /* to make custome pinmarke with orang color and animation and if your pinmark is your location don't do anything */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{return nil}
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    /* to get my location coordinate and enable me to do zoomin inregion 1000M from my cooridante*/
    func CenterMapOnUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else{return}
        let coordinateRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    /*to make apinmark and display it in my map and if thier is pinmark remove the old pinmark and draw new pin mark*/
    @objc func dropPin(sender: UITapGestureRecognizer){
        removePin()
        removeSpinner()
        removeProgressLable()
        cancelAllSessions()
        imageArray = []
        imageUrlArray = []
        collectionView?.reloadData()
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLable()
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegion.init(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImage(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLable()
                        self.collectionView?.reloadData()
                    }
                })
            }

        }
    }
    
    func removePin(){
        for annotation in mapView.annotations{
            mapView.removeAnnotation(annotation)
        }
       
    }
    
    // this function to retrieve image url using alamofire and anppend it in array bof imageurl to use alamofireimage to download all images in this array
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping(_ status: Bool) -> ()){
        Alamofire.request(flickerUrl(forApiKey: apikey, withAnnotation: annotation, andNumberOfPhotos: 28)).responseJSON {(response) in
            guard let jsonDict = response.result.value as? Dictionary<String, AnyObject> else{return}
            let photoDict = jsonDict["photos"] as! Dictionary<String, AnyObject>
            let photoDictArray = photoDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photoDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
              handler(true)
        }
    }
    
    // use alamofire_image to download all image from imageUrlArray
    func retrieveImage(handler: @escaping (_ status: Bool)->()){
        for url in imageUrlArray {
        Alamofire.request(url).responseImage(completionHandler: {(response) in
            guard let image = response.result.value else{ return }
            self.imageArray.append(image)
            self.progressLable?.text = "\(self.imageArray.count)/ 28 IMAGES DOWNLOADED "
            if self.imageArray.count == self.imageUrlArray.count {
                handler(true)
            }
         })
      }
    }
    
    // to cancel downloading image if uer cancel process
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    /*this func to alwas get my current location at any time*/
    func configureLocationServices(){
        if authorizationStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        }else{
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        CenterMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else{return UICollectionViewCell()}
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forIamge: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

