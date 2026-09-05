// Generated code. Do not edit.
package com.example.api.showcase.samplemodels

import com.example.api.AuditStamp
import com.example.api.DateInterval
import com.example.api.GeneratedResponse
import com.example.api.NamedObject
import com.example.api.showcase.samplemodels.models.EmailNotification
import com.example.api.showcase.samplemodels.models.NotificationEnvelope
import com.example.api.showcase.samplemodels.models.PrimitiveMatrix
import com.example.api.showcase.samplemodels.models.PushNotification
import com.example.api.showcase.samplemodels.models.SampleScore
import com.example.api.showcase.shared.SampleVisibility
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

interface ShowcaseSampleModelsService {
    suspend fun getMatrix(request: ShowcaseSampleModelsGetMatrixRequest): GeneratedResponse<PrimitiveMatrix>

    suspend fun createNotification(request: ShowcaseSampleModelsCreateNotificationRequest): GeneratedResponse<NotificationEnvelope>
}

@ConditionalOnMissingBean(ShowcaseSampleModelsService::class)
@Service
class NotImplementedShowcaseSampleModelsService : ShowcaseSampleModelsService {
    override suspend fun getMatrix(request: ShowcaseSampleModelsGetMatrixRequest): GeneratedResponse<PrimitiveMatrix> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)

    override suspend fun createNotification(request: ShowcaseSampleModelsCreateNotificationRequest): GeneratedResponse<NotificationEnvelope> =
        throw ResponseStatusException(HttpStatus.NOT_IMPLEMENTED)
}
