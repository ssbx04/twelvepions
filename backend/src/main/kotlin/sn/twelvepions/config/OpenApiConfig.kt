package sn.twelvepions.config

import io.swagger.v3.oas.models.Components
import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class OpenApiConfig {

    @Bean
    fun openApi(): OpenAPI {
        val securityScheme = SecurityScheme()
            .type(SecurityScheme.Type.HTTP)
            .scheme("bearer")
            .bearerFormat("JWT")
            .description("JWT obtenu via POST /auth/verify-otp")

        return OpenAPI()
            .info(
                Info()
                    .title("12 Pions API")
                    .version("0.0.1")
                    .description(
                        "API du jeu de dames sénégalais. " +
                            "Auth par OTP SMS (numéro `+221XXXXXXXXX`). " +
                            "En dev, le code OTP est imprimé dans le terminal du backend.",
                    )
                    .contact(Contact().name("12 Pions").email("contact@12pions.example"))
                    .license(License().name("Proprietary")),
            )
            .components(Components().addSecuritySchemes("bearerAuth", securityScheme))
            .addSecurityItem(SecurityRequirement().addList("bearerAuth"))
    }
}
