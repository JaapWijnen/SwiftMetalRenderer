protocol Library {
    associatedtype Title
    associatedtype Book
        
    subscript(_ type: Title) -> Book { get }
    
    init()
}
