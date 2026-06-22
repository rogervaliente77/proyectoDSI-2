# app/services/calculadora_sv_service.rb
class CalculadoraSvService
  # Techos 2026 (Ajustar según leyes vigentes)
  TECHO_ISSS = 1000.00
  PORCENTAJE_ISSS = 0.03
  PORCENTAJE_AFP = 0.0725

  def self.calcular_isss(sueldo)
    [sueldo, TECHO_ISSS].min * PORCENTAJE_ISSS
  end

  def self.calcular_afp(sueldo)
    sueldo * PORCENTAJE_AFP
  end

  def self.calcular_renta(salario_gravable, periodo = :quincenal)
    # Ejemplo de tabla de Renta Quincenal simplificada
    case periodo
    when :quincenal
      if salario_gravable <= 236.00
        0.0
      elsif salario_gravable <= 447.43
        (salario_gravable - 236.00) * 0.10 + 8.83
      elsif salario_gravable <= 1019.05
        (salario_gravable - 447.43) * 0.20 + 30.00
      else
        (salario_gravable - 1019.05) * 0.30 + 144.32
      end
    end
  end
end