import Foundation

struct DiaryNotice: Equatable {
    var whatWentWrong: String
    var whatToDoNext: String
}

enum DiaryFeedback {
    static let couldNotReadDiary = DiaryNotice(
        whatWentWrong: "The diary could not be read.",
        whatToDoNext: "Leave this screen and come back."
    )

    static let couldNotSaveDiary = DiaryNotice(
        whatWentWrong: "The diary could not be saved.",
        whatToDoNext: "Try again. If it keeps happening, leave this screen and come back."
    )
}
