// Generated code. Do not edit.
package com.example.api

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// Generated code. Modify at your own risk.
@Serializable
enum class StructureType(
    val rawValue: String,
) : Identifiable<String> {
    @SerialName("plant")
    Plant("plant"),

    @SerialName("production_line")
    ProductionLine("production_line"),

    @SerialName("workstation")
    Workstation("workstation"),

    @SerialName("equipment")
    Equipment("equipment"),
    ;

    override val id: String
        get() = rawValue
    companion object {
        fun fromValue(value: String): StructureType =
            entries.firstOrNull { it.rawValue == value }
                ?: throw IllegalArgumentException("Unknown StructureType value: $value")
    }
}
