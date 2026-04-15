//
//  OnboardingExperienceView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI

struct OnboardingExperienceView: View {

    @ObservedObject var viewModel: OnboardingViewModel

    let options: [(title: String, description: String, level: ExperienceLevel)] = [
        ("향수를 처음 시작했어요!", "향수에 대한 계열이나 노트를 전혀 몰라요", .beginner),
        ("향수를 가끔씩 뿌려요!", "향수의 계열이나 노트의 존재를 인지하는 정도예요", .casual),
        ("향수를 꽤 알고 있어요!", "향수 계열이나 노트의 개념을 알고, 종류도 알아요", .expert)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            ProgressView(value: 1, total: 3)
                .padding(.horizontal)

            Text("현재 당신의\n향수 경험을 알려주세요")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(options, id: \.title) { option in
                    Button {
                        viewModel.selectedExperience = option.level
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.black)

                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.selectedExperience == option.level
                                    ? Color.black
                                    : Color.gray.opacity(0.3),
                                    lineWidth: viewModel.selectedExperience == option.level ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }

            Spacer()

            Button {
                viewModel.currentStep = .taste
            } label: {
                Text("다음")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.selectedExperience != nil
                        ? Color.black
                        : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(viewModel.selectedExperience == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }
}
