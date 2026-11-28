//
//  HelpTopic.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct HelpTopic: Hashable {
    let title: String
    let answer: String

    static let faq = [
        HelpTopic(
            title: "Booking dokter",
            answer: "Pilih dokter, slot praktik, lalu isi alasan kunjungan. Status permintaan tersedia di My Appointments."
        ),
        HelpTopic(
            title: "Mengubah atau membatalkan jadwal",
            answer: "Buka appointment aktif untuk memilih slot baru atau mengirim permintaan pembatalan."
        ),
        HelpTopic(
            title: "Mengunggah dokumen",
            answer: "Buka Documents & BPJS. Pilih PDF, JPEG, atau PNG dengan ukuran maksimal 5 MiB."
        )
    ]
}
