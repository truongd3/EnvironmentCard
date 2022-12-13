import UIKit

class SecondViewController: UIViewController, UITextViewDelegate {
    var check: String!
    func setGradientBackground() {
        let colorTop =  UIColor(red: 128/255, green: 203/255, blue: 196/255, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
// Decoration
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var answerTextField: UITextField!
    @IBOutlet weak var option1TextField: UITextField!
    @IBOutlet weak var option2TextField: UITextField!
// Declare main screen
    var flashcardsController: FirstController!
// Initial screen
    override func viewDidLoad() {
        setGradientBackground()
        super.viewDidLoad()
        // Setup question text view (placeholder + border radius)
        questionTextView.layer.cornerRadius = 10 // border radius
        questionTextView.clipsToBounds = true // border radius
        questionTextView.text = "Question"
        questionTextView.textColor = UIColor.lightGray
        questionTextView.font = UIFont(name: "TimesNewRomanPSMT", size: 25)
        questionTextView.returnKeyType = .done
        questionTextView.delegate = self
        
        // Setup answer text field (green background)
        self.answerTextField.backgroundColor = UIColor(red: 0xd0/255, green: 0xff/255, blue: 0x5b/255, alpha: 1.0)
        // Alert Add or Edit
        let alert = UIAlertController(title: "EDIT or ADD", message: "Edit current card or add new card?", preferredStyle: .alert)
        let editAction = UIAlertAction(title: "Edit", style: .destructive) { action in
            let currentCard = self.flashcardsController.flashcards[self.flashcardsController.currentIndex]
            self.questionTextView.text = currentCard.question
            self.answerTextField.text = currentCard.answer
            self.option1TextField.text = currentCard.option1
            self.option2TextField.text = currentCard.option2
            self.check = "edit"
        }
        let addAction = UIAlertAction(title: "Add", style: .destructive){ action in
            self.questionTextView.isHidden = false
            self.answerTextField.isHidden = false
            self.option1TextField.isHidden = false
            self.option2TextField.isHidden = false
            self.check = "add"
        }
        alert.addAction(editAction)
        alert.addAction(addAction)
        present(alert, animated: true)
    }
    
    @IBAction func didTapOnCancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func didTapOnDone(_ sender: Any) {
        let questionText = questionTextView.text
        let answerText = answerTextField.text
        let option1 = option1TextField.text
        let option2 = option2TextField.text
        
        let alert = UIAlertController(title: "Missing text", message: "Enter all of required information", preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default)
        alert.addAction(continueAction)
        if (questionText == nil || answerText == nil || questionText!.isEmpty || answerText!.isEmpty || option1 == nil || option2 == nil || option1!.isEmpty || option2!.isEmpty) {
            present(alert, animated: true)
        }
        else {
            if (check == "add"){
                if (flashcardsController.currentIndex == flashcardsController.flashcards.count - 1){
                    flashcardsController.Next_Deco.isHidden = false
                }
                flashcardsController.updateFlashcard(question: questionText!, answer: answerText!, option1: option1!, option2: option2!)
                flashcardsController.saveAllFlashcardsToDisk()
            }
            else if (check == "edit"){
                flashcardsController.flashcards[flashcardsController.currentIndex] = Flashcard(question: questionText!, answer: answerText!, option1: option1!, option2: option2!)
                flashcardsController.setupAnswers()
                flashcardsController.saveAllFlashcardsToDisk()
            }
            dismiss(animated: true)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Question" {
            textView.text = ""
            textView.textColor = UIColor.black
            textView.font = UIFont(name: "TimesNewRomanPSMT", size: 25)
        }
    }
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
        
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Question"
            textView.textColor = UIColor.lightGray
            textView.font = UIFont(name: "TimesNewRomanPSMT", size: 25)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

