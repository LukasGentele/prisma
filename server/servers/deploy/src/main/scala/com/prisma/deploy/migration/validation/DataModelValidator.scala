package com.prisma.deploy.migration.validation

import com.prisma.deploy.connector.FieldRequirementsInterface
import com.prisma.shared.models.ConnectorCapabilities
import org.scalactic.Or

case class DataModelValidationResult(dataModel: PrismaSdl, warnings: Vector[DeployWarning])

trait DataModelValidator {
  def validate(
      dataModel: String,
      fieldRequirements: FieldRequirementsInterface,
      capabilities: ConnectorCapabilities
  ): DataModelValidationResult Or Vector[DeployError]
}
