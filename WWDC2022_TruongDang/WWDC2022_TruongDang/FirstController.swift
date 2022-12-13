import UIKit
import ImageIO
import SwiftUI
import SAConfettiView

struct Flashcard {
    var question: String
    var answer: String
    var option1: String
    var option2: String
}

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

extension UIImage {
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithURL(_ gifUrl:String) -> UIImage? {
        guard let bundleURL:URL? = URL(string: gifUrl)
            else {
                print("image named \"\(gifUrl)\" doesn't exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL!) else {
            print("image named \"\(gifUrl)\" into NSData")
            return nil
        }
        return gifImageWithData(imageData)
    }
    
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        return gifImageWithData(imageData)
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        delay = delayObject as! Double
        if (delay < 0.1) {
            delay = 0.1
        }
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if (b == nil || a == nil) {
            if (b != nil) {
                return b!
            } else if (a != nil) {
                return a!
            } else {
                return 0
            }
        }
        if (a < b) {
            let c = a
            a = b
            b = c
        }
        var rest: Int
        while true {
            rest = a! % b!
            if (rest == 0) {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i), source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        let duration: Int = {
            var sum = 0
            for val: Int in delays {
                sum += val
            }
            return sum
        }()
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            for _ in 0..<frameCount { frames.append(frame) }
        }
        let animation = UIImage.animatedImage(with: frames, duration: Double(duration)/1000.0)
        return animation
    }
}

class CellClass: UITableViewCell {}

extension FirstController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            print("Practice mode")
            mode = "practice"
            PracticeMode()
        }
        else if (indexPath.row == 1){
            print("Quiz mode")
            mode = "quiz"
            QuizMode()
        }
        removeTransparentView()
    }
}

class FirstController: UIViewController {
    @IBOutlet weak var Screen: UIView!
    @IBOutlet weak var Question: UILabel!
    @IBOutlet weak var Answer: UILabel!
    @IBOutlet weak var card: UIView!
    
    @IBOutlet weak var Button1_Deco: UIButton!
    @IBOutlet weak var Button2_Deco: UIButton!
    @IBOutlet weak var Button3_Deco: UIButton!
    
    @IBOutlet weak var Next_Deco: UIButton!
    @IBOutlet weak var Prev_Deco: UIButton!
    @IBOutlet weak var Delete_Deco: UIButton!
    @IBOutlet weak var Menu_Deco: UIButton!
    @IBOutlet weak var Plus_Deco: UIButton!
    @IBOutlet weak var Start_Deco: UIButton!
    @IBOutlet weak var TimerLabel: UILabel!
    @IBOutlet weak var HighscoreLabel: UILabel!
    @IBOutlet weak var Circle_Deco: UIImageView!
    @IBOutlet weak var CurrentScore_Deco: UILabel!
    
    var timer: Timer = Timer()
    var count: Int = 15 // initial seconds
    var timerCounting: Bool = false
    @IBAction func ButtonStart(_ sender: Any) {
        GamePlay(index: currentIndex)
    }
    @objc func timerCounter() -> Void {
        count = count - 1
        TimerLabel.text = "Timer: \(count)"
        if (count == 0){
            count = 0
            wrong_attempts = wrong_attempts - 1
            timer.invalidate()
            timerCounting = false
            if (wrong_attempts == 0){ // Lose
                print("Lose (time limit)")
                let alert = UIAlertController(title: "Game Over", message: "You run out of allowed attempts", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { action in
                    self.QuizMode()
                    self.SaveHighScore()
                    self.Circle_Deco.isHidden = true
                    self.CurrentScore_Deco.isHidden = true
                }
                alert.addAction(okAction)
                present(alert, animated: true)
            }
            else if (wrong_attempts > 0){
                print("Lose 1 attempt (time limit)")
                let alert = UIAlertController(title: "Time Limit", message: "You have \(wrong_attempts) attempts left.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { [self] action in
                    self.count = 16
                    self.timerCounting = true
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
                }
                alert.addAction(okAction)
                present(alert, animated: true)
            }
        }
    }
    @objc func CurrentScore() -> Void {
        CurrentScore_Deco.text = "\(correct_attempts)"
    }
    
    var flashcards = [Flashcard]() // array to hold our flashcards
    var currentIndex = 0 // current question
    var num_back_screen = 5
    var wrong_attempts = 3
    var correct_attempts = 0
    var high_score = 0
    var mode = "practice"
    
    // Initialization flashcard questions, will fix the code soon
    let card1 = Flashcard(question: "What country consumes the most energy in the world?", answer: "The United States", option1: "China", option2: "India")
    let card2 = Flashcard(question: "What is the leading source of energy in the United States?", answer: "Oil", option1: "Nuclear Power", option2: "Coal")
    let card3 = Flashcard(question: "What are harmful materials in the environment?", answer: "Pollution", option1: "Recycle", option2: "Non-renewable")
    let card4 = Flashcard(question: "What type of resource is a tree?", answer: "Natural", option1: "Fresh", option2: "Capitol")
    // When click 3 buttons
    @IBAction func Button1(_ sender: Any) {
        Button1_Deco.layer.borderWidth = 3.14
        if (Button1_Deco.titleLabel?.text == Answer.text){
            Button1_Deco.layer.borderColor = CGColor(red: 0x35/255, green: 0xe0/255, blue: 0x5d/255, alpha: 1.0)
            Answer.isHidden = false
            Answer.textColor = UIColor(red: 0x34/255, green: 0xc7/255, blue: 0x59/255, alpha: 1.0)
            flipFlashcard()
        }
        else {Button1_Deco.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.1733349173, alpha: 1)}
        if (mode == "quiz"){
            Choose1Ans(button: Button1_Deco, index: currentIndex)
            Next_Deco.isHidden = true
            Prev_Deco.isHidden = true
            Plus_Deco.isHidden = true
        }
    }
    @IBAction func Button2(_ sender: Any) {
        Button2_Deco.layer.borderWidth = 3.14
        if (Button2_Deco.titleLabel?.text == Answer.text){
            Button2_Deco.layer.borderColor = CGColor(red: 0x35/255, green: 0xe0/255, blue: 0x5d/255, alpha: 1.0)
            Answer.isHidden = false
            Answer.textColor = UIColor(red: 0x34/255, green: 0xc7/255, blue: 0x59/255, alpha: 1.0)
            flipFlashcard()
        }
        else {Button2_Deco.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.1733349173, alpha: 1)}
        if (mode == "quiz"){
            Choose1Ans(button: Button2_Deco, index: currentIndex)
            Next_Deco.isHidden = true
            Prev_Deco.isHidden = true
            Plus_Deco.isHidden = true
        }
    }
    @IBAction func Button3(_ sender: Any) {
        Button3_Deco.layer.borderWidth = 3.14
        if (Button3_Deco.titleLabel?.text == Answer.text){
            Button3_Deco.layer.borderColor = CGColor(red: 0x35/255, green: 0xe0/255, blue: 0x5d/255, alpha: 1.0)
            Answer.textColor = UIColor(red: 0x34/255, green: 0xc7/255, blue: 0x59/255, alpha: 1.0)
            Answer.isHidden = false
            flipFlashcard()
        }
        else {Button3_Deco.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0.1733349173, alpha: 1)}
        if (mode == "quiz"){
            Choose1Ans(button: Button3_Deco, index: currentIndex)
            Next_Deco.isHidden = true
            Prev_Deco.isHidden = true
            Plus_Deco.isHidden = true
        }
    }
    @IBAction func ButtonNext(_ sender: Any) {
        currentIndex = currentIndex + 1
        Answer.isHidden = true
        Question.isHidden = false
        updateNextPrevButtons()
        animateCardOut()
        Screen.backgroundColor = UIColor(patternImage: UIImage(named: "back_screen\(Int.random(in: 1..<(num_back_screen+1)))")!)
    }
    @IBAction func ButtonPrev(_ sender: Any) {
        Answer.isHidden = true
        if (currentIndex > 0){
            currentIndex = currentIndex - 1
            Question.isHidden = false
            animateCardOut_Prev()
            updateNextPrevButtons()
        }
        Screen.backgroundColor = UIColor(patternImage: UIImage(named: "back_screen\(Int.random(in: 1..<(num_back_screen+1)))")!)
    }
// Delete a flashcard
    @IBAction func ButtonDelete(_ sender: Any) {
        let alert = UIAlertController(title: "Delete flashcard", message: "Are you sure to delete this question?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { action in self.deleteCurrentFlashcard()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    func deleteCurrentFlashcard(){
        if (flashcards.count > 0) {flashcards.remove(at: currentIndex)}
        if (flashcards.count == 0){ // check there are no cards remaining
            currentIndex = 0
            Question.text = "Click + below to add more questions"
            Answer.text = "Click + below to add more questions"
            Button1_Deco.titleLabel?.text = "All cards deleted"
            Button2_Deco.titleLabel?.text = "Click + to add more"
            Button3_Deco.titleLabel?.text = "Re-open to restart"
        } else if(currentIndex == flashcards.count){//check the last index is deleted
            currentIndex = flashcards.count - 1
            setupAnswers()
        } else { // index is between 2 ends
            setupAnswers()
        }
        saveAllFlashcardsToDisk()
        updateNextPrevButtons()
        Question.isHidden = false
    }
// Update status of Next and Prev buttons
    func updateNextPrevButtons(){
        if (currentIndex == flashcards.count - 1) {
            Next_Deco.isEnabled = false
        } else {
            Next_Deco.isEnabled = true
        }
        if (currentIndex == 0){
            Prev_Deco.isEnabled = false
        } else {
            Prev_Deco.isEnabled = true
        }
        if (flashcards.count == 0){
            Next_Deco.isEnabled = false
            Prev_Deco.isEnabled = false
            Delete_Deco.isEnabled = false
        } else {
            Delete_Deco.isEnabled = true
        }
    }
// When tap the card
    @IBAction func TapScreen(_ sender: Any) {
        if (mode == "practice"){
            Answer.isHidden = false
            Answer.textColor = UIColor(red: 0xff/255, green: 0x00/255, blue: 0x40/255, alpha: 1.0)
            flipFlashcard()
            Next_Deco.isHidden = false
        }
    }
// Random options, updateLabels
    func setupAnswers(){
        let buttons = [Button1_Deco, Button2_Deco, Button3_Deco]
        var count:[Int] = [0, 1, 2]
        let currentFlashcard = flashcards[currentIndex]
        
        Question.text = currentFlashcard.question
        Answer.text = currentFlashcard.answer
        
        let first = count.randomElement()!
        count = count.filter {$0 != first}
        buttons[first]?.setTitle(currentFlashcard.answer, for: .normal)
        let second = count.randomElement()!
        count = count.filter {$0 != second}
        buttons[second]?.setTitle(currentFlashcard.option1, for: .normal)
        let third = count[0]
        count = count.filter {$0 != third}
        buttons[third]?.setTitle(currentFlashcard.option2, for: .normal)
        //------------------------------------------------------
        // Button 1 setup
        Button1_Deco.layer.cornerRadius = 5
        Button1_Deco.clipsToBounds = true
        Button1_Deco.layer.borderWidth = 0
        // Button 2 setup
        Button2_Deco.layer.cornerRadius = 5
        Button2_Deco.clipsToBounds = true
        Button2_Deco.layer.borderWidth = 0
        // Button 3 setup
        Button3_Deco.layer.cornerRadius = 5
        Button3_Deco.clipsToBounds = true
        Button3_Deco.layer.borderWidth = 0
    }
// Add card to the array
    func updateFlashcard(question: String, answer: String, option1: String, option2: String){
        let flashcard = Flashcard(question: question, answer: answer, option1: option1, option2: option2)
        flashcards.append(flashcard)
        updateNextPrevButtons()
        saveAllFlashcardsToDisk()
    }
// Flip animation
    func flipFlashcard() {
        if (Question.isHidden == false){ // show answer
            Answer.isHidden = false
            UIView.transition(with: Answer, duration: 0.3, options: .transitionFlipFromTop, animations: {self.Question.isHidden = !self.Question.isHidden
            })
            Next_Deco.isHidden = false
        }
        else { // show question
            UIView.transition(with: Answer, duration: 0.3, options: .transitionFlipFromBottom, animations: {self.Question.isHidden = !self.Question.isHidden
            })
            Answer.isHidden = true
            Next_Deco.isHidden = true
        }
    }
// Next card - animation
    func animateCardOut() {
        UIView.animate(withDuration: 0.1, animations: {
            self.card.transform = CGAffineTransform.identity.translatedBy(x:-400,y:0)
        }, completion: {finished in
            self.setupAnswers()
            self.animateCardIn()
        })
    }
    func animateCardIn(){
        card.transform = CGAffineTransform.identity.translatedBy(x:400,y:0)
        UIView.animate(withDuration: 0.1) {
            self.card.transform = CGAffineTransform.identity
        }
    }
// Next card - animation - PREV
    func animateCardOut_Prev() {
        UIView.animate(withDuration: 0.1, animations: {
            self.card.transform = CGAffineTransform.identity.translatedBy(x:400,y:0)
        }, completion: {finished in
            self.setupAnswers()
            self.animateCardIn_Prev()
        })
    }
    func animateCardIn_Prev(){
        card.transform = CGAffineTransform.identity.translatedBy(x:-400,y:0)
        UIView.animate(withDuration: 0.1) {
            self.card.transform = CGAffineTransform.identity
        }
    }
// Save card to disk
    func saveAllFlashcardsToDisk(){
        let dictionaryArray = flashcards.map { (card) -> [String: String] in
            return ["question": card.question, "answer": card.answer, "option1": card.option1, "option2": card.option2]
        }
        UserDefaults.standard.set(dictionaryArray, forKey: "flashcards")
        print("Card saved")
    }
// Read card from disk
    func readSavedFlashcards(){
        let dictionaryArray = UserDefaults.standard.array(forKey: "flashcards")
        if let dictionaryArray = UserDefaults.standard.array(forKey: "flashcards") as? [[String: String]]{
            let savedCards = dictionaryArray.map { dictionary -> Flashcard in
                return Flashcard(question: dictionary["question"]!, answer: dictionary["answer"]!, option1: dictionary["option1"]!, option2: dictionary["option2"]!)
            }
            flashcards.append(contentsOf: savedCards)
        }
    }
    
    
// Initial setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gifcircle = UIImage.gifImageWithName("gif_circle")
        Circle_Deco.image = gifcircle
        Circle_Deco.isHidden = true
        CurrentScore_Deco.isHidden = true
        
        HighscoreLabel.layer.cornerRadius = 30
        HighscoreLabel.clipsToBounds = true
        HighscoreLabel.layer.borderColor = CGColor(red: 0xff/255, green: 0x00/255, blue: 0x19/255, alpha: 1.0)
        HighscoreLabel.layer.borderWidth = 3.14
        HighscoreLabel.backgroundColor = UIColor(red: 0xff/255, green: 0x00/255, blue: 0xe5/255, alpha: 0.15)
        
        PracticeMode()

        UserDefaults.standard.setValue(0, forKey: "highscore") // You can uncomment this line after 1st run
        print("Current high score: \(UserDefaults.standard.value(forKey: "highscore") as! Int)")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CellClass.self, forCellReuseIdentifier: "Cell")
        
    // Back Screen set up
        Screen.backgroundColor = UIColor(patternImage: UIImage(named: "back_screen1")!)
        Screen.layer.shadowRadius = 15.0
        Screen.layer.shadowOpacity = 1
    // Question set up
        Question.textColor = .white
        Question.layer.cornerRadius = 10 // border radius
        Question.clipsToBounds = true // border radius
        Question.backgroundColor = UIColor(red: 0x80/255, green: 0xcb/255, blue: 0xc4/255, alpha: 0.5)
        Question.isHidden = false
    // Answer setup
        Answer.textColor = UIColor(red: 0x34/255, green: 0xc7/255, blue: 0x59/255, alpha: 1.0)
        Answer.layer.cornerRadius = 10 // border radius
        Answer.layer.masksToBounds = true // border radius
        Answer.backgroundColor = UIColor(red: 0xb2/255, green: 0xdf/255, blue: 0xdb/255, alpha: 0.6)
        Answer.isHidden = true
    // Button NEXT setup
        Next_Deco.isHidden = true
        
        currentIndex = 0
        readSavedFlashcards()
        if (flashcards.count == 0){
            updateFlashcard(question: card1.question, answer: card1.answer, option1: card1.option1, option2: card1.option2)
            updateFlashcard(question: card2.question, answer: card2.answer, option1: card2.option1, option2: card2.option2)
            updateFlashcard(question: card3.question, answer: card3.answer, option1: card3.option1, option2: card3.option2)
            updateFlashcard(question: card4.question, answer: card4.answer, option1: card4.option1, option2: card4.option2)
            setupAnswers()
            saveAllFlashcardsToDisk()
        }
        else {
            setupAnswers()
        }
        updateNextPrevButtons()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let creationController = navigationController.topViewController as! SecondViewController
        creationController.flashcardsController = self
    }
    
    @IBAction func ButtonMenu(_ sender: Any) {
        dataSource = ["Practice Mode", "Quiz Mode"]
        selectedButton = Menu_Deco
        addTransparentView(frames: Menu_Deco.frame)
    }
    
    let transparentView = UIView()
    let tableView = UITableView()
    var selectedButton = UIButton()
    var dataSource = [String]()
    func addTransparentView(frames: CGRect) {
        let window = UIApplication.shared.keyWindow
        transparentView.frame = window?.frame ?? self.view.frame
        self.view.addSubview(transparentView)
             
        tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: 0, height: 0)
        self.view.addSubview(tableView)
        tableView.layer.cornerRadius = 5
             
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        tableView.reloadData()
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeTransparentView))
        transparentView.addGestureRecognizer(tapgesture)
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0.5
            self.tableView.frame = CGRect(x: frames.origin.x-160, y: frames.origin.y + frames.height + 5, width: 160, height: CGFloat(self.dataSource.count * 61))
        }, completion: nil)
    }
    @objc func removeTransparentView() {
        let frames = selectedButton.frame
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: 0, height: 0)
        }, completion: nil)
    }
    
    func QuizMode() {
        HighscoreLabel.text = "High score: \(readSavedHighscore())"
        Start_Deco.isHidden = false
        Button1_Deco.isEnabled = false
        Button2_Deco.isEnabled = false
        Button3_Deco.isEnabled = false
        Question.isEnabled = false
        Question.isHidden = false
        Delete_Deco.isEnabled = false
        HighscoreLabel.isHidden = false
        Next_Deco.isHidden = true
        Prev_Deco.isHidden = true
        Plus_Deco.isHidden = true
    }
    func PracticeMode() {
        // Highscore.isHidden = true
        timerCounting = false
        timer.invalidate()
        Start_Deco.isHidden = true
        TimerLabel.isHidden = true
        Button1_Deco.isEnabled = true
        Button2_Deco.isEnabled = true
        Button3_Deco.isEnabled = true
        Question.isEnabled = true
        Delete_Deco.isEnabled = true
        HighscoreLabel.isHidden = true
        Next_Deco.isHidden = false
        Prev_Deco.isHidden = false
        Plus_Deco.isHidden = false
        Circle_Deco.isHidden = true
        CurrentScore_Deco.isHidden = true
    }
    
    func Choose1Ans(button: UIButton, index: Int){
        if (button.titleLabel?.text != Answer.text){ // wrong answer
            wrong_attempts -= 1 // Minus
            timerCounting = false
            timer.invalidate()
            if (wrong_attempts == 0){ // Run out of attempts LOSE
                print("Lose (run out attempts)")
                let alert = UIAlertController(title: "Game Over", message: "You run out of allowed attempts", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { action in
                    self.SaveHighScore() // save high score
                    self.QuizMode()
                    self.TimerLabel.isHidden = true
                    self.Circle_Deco.isHidden = true
                    self.CurrentScore_Deco.isHidden = true
                }
                alert.addAction(okAction)
                present(alert, animated: true)
            }
            else if (wrong_attempts > 0){
                print("Lose 1 attempt (wrong answer)")
                let alert = UIAlertController(title: "Incorrect", message: "You have \(wrong_attempts) attempts left.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { action in
                    self.timerCounting = true
                    self.count = 16
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerCounter), userInfo: nil, repeats: true)
                }
                alert.addAction(okAction)
                present(alert, animated: true)
            }
        }
        else if (button.titleLabel?.text == Answer.text){// correct answer
            correct_attempts += 1
            CurrentScore()
            if (correct_attempts == flashcards.count){ // Win
                Answer.isHidden = false
                flipFlashcard()
                // Bravo when win (Confetti)
                let confettiView = SAConfettiView(frame: self.view.bounds)
                confettiView.type = .Cup
                confettiView.colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.blue, UIColor.purple]
                confettiView.intensity = 0.75
                view.addSubview(confettiView)
                confettiView.startConfetti()
                print("Win")
                let alert = UIAlertController(title: "Game Win", message: "You Rockkkk", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { action in
                    self.timer.invalidate()
                    self.TimerLabel.isHidden = true
                    self.SaveHighScore() // save high score
                    self.QuizMode()
                    self.Circle_Deco.isHidden = true
                    self.CurrentScore_Deco.isHidden = true
                    confettiView.stopConfetti() // End bravo
                }
                alert.addAction(okAction)
                present(alert, animated: true)
            }
            else { // Next card
                Answer.isHidden = true
                currentIndex = currentIndex + 1
                Question.isHidden = false
                animateCardOut()
                updateNextPrevButtons()
                Screen.backgroundColor = UIColor(patternImage: UIImage(named: "back_screen\(Int.random(in: 1..<(num_back_screen+1)))")!)
                count = 16
            }
        }
    }
    func GamePlay(index: Int){
        wrong_attempts = 3
        correct_attempts = 0 // init score
        CurrentScore() // current score appear
        currentIndex = 0
        setupAnswers()
        HighscoreLabel.isHidden = true
        timerCounting = true
        count = 15
        TimerLabel.isHidden = false
        Start_Deco.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        Button1_Deco.isEnabled = true
        Button2_Deco.isEnabled = true
        Button3_Deco.isEnabled = true
        Question.isEnabled = true
        Circle_Deco.isHidden = false
        CurrentScore_Deco.isHidden = false
    } 
    func SaveHighScore(){
        if (correct_attempts > readSavedHighscore()){
            high_score = correct_attempts
            print("New highscore saved: \(high_score)")
            UserDefaults.standard.setValue(high_score, forKey: "highscore")
        }
        else {
            print("Not highscore")
        }
    }
    func readSavedHighscore() -> Int{
        print("Current high score: \(UserDefaults.standard.value(forKey: "highscore") as! Int)")
        return UserDefaults.standard.value(forKey: "highscore") as! Int
    }
}

