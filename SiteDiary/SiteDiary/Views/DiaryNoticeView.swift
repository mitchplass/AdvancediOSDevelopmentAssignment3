import SwiftUI

struct DiaryNoticeView: View {
    let notice: DiaryNotice

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DiarySymbol(name: DiarySymbols.notice)
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(notice.whatWentWrong)
                    .font(.headline)
                Text(notice.whatToDoNext)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}
