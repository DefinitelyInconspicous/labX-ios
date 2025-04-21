import SwiftUI
import Forever

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    
    var consultation: consultation
    @Binding var consultations: [consultation]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.top, 40)

            Text(consultation.teacher.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                    Text(consultation.date.formatted(date: .long, time: .shortened))
                }

                if !consultation.comment.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "text.bubble")
                        Text(consultation.comment)
                    }
                }
            }
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
            
            Button(role: .destructive) {
                cancelConsultation()
            } label: {
                Label("Cancel Consultation", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("Consultation Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    func cancelConsultation() {
        if let index = consultations.firstIndex(where: { $0.id == consultation.id }) {
            consultations.remove(at: index)
        }
        dismiss()
    }
}


#Preview {
    DetailView(consultation: consultation(teacher: staff(name: "", email: ""), date: .now, comment: ""), consultations: .constant([]))
}
