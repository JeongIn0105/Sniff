//
//  OnboardingExperienceView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI

struct OnboardingExperienceView: View {

    @ObservedObject var viewModel: OnboardingViewModel
    private let options = OnboardingExperienceOption.all

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            ProgressView(value: 2, total: 4)
                .padding(.horizontal)

            Text(AppStrings.Onboarding.experienceTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal)

            Text(AppStrings.Nickname.welcome(nickname: viewModel.nickname))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(options) { option in
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
                Text(AppStrings.Onboarding.next)
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
