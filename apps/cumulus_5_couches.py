import appdaemon.plugins.hass.hassapi as hass

class Cumulus5Couches(hass.Hass):

    def initialize(self):
        # Appelée au démarrage d'AppDaemon
        self.log("Cumulus5Couches - initialisation")

        # Planifier une mise à jour toutes les minutes
        self.run_every(self.update_model, "now", 60)

    def update_model(self, kwargs):
        # Récupérer les valeurs de base dans HA
        t_bas = self.get_state("sensor.thermo_cumulus_temperature")
        heures_depuis = self.get_state("sensor.cumulus_heures_depuis_derniere_chauffe")
        t_cible = self.get_state("input_number.cumulus_temperature_cible_hc")

        # Log simple pour vérifier la connexion
        self.log(
            f"Update Cumulus 5 couches - T_bas={t_bas}, "
            f"heures_depuis={heures_depuis}, T_cible={t_cible}"
        )

        # TODO : ici on mettra le calcul des 5 couches
        # et la publication des sensors dans HA
