// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility

data class ShowcaseSampleModelsGetMatrixRequest(
    val matrixId: String,
    val visible: Boolean = true,
    val visibility: SampleVisibility = SampleVisibility.fromValue("public"),
    val scores: List<SampleScore> = listOf(SampleScore.fromValue(100)),
    val traceId: String?,
    val sampleSession: String?,
    val apiKey: String?,
)
