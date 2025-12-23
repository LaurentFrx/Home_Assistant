import appdaemon.plugins.hass.hassapi as hass
import math


class Cumulus5Couches(hass.Hass):
    """
    Modèle simplifié de stratification 5 couches pour ballon 300 L.

    Capteurs créés dans Home Assistant :
      - sensor.cumulus_v3_temp_couche_1_c .. _5_c
      - sensor.cumulus_v3_temp_moyenne_5c_c
      - sensor.cumulus_v3_litres_40c_equivalents_5c
      - sensor.cumulus_v3_douches_disponibles_5c
    """

    def initialize(self):
        self.log("Cumulus5Couches - initialisation")

        # Entités configurables (avec valeurs par défaut)
        self.entity_temp_bas = self.args.get(
            "sensor_temp_bas", "sensor.thermo_cumulus_temperature"
        )
        self.entity_last_heat = self.args.get(
            "sensor_derniere_chauffe", "sensor.cumulus_derniere_chauffe_timestamp"
        )
        self.entity_consigne = self.args.get(
            "input_temp_cible", "input_number.cumulus_temperature_cible_pv"
        )

        # Périodicité de mise à jour (en secondes)
        self.update_interval = int(self.args.get("update_interval_seconds", 300))

        # Premier calcul rapidement après le démarrage
        self.run_in(self.update_cumulus, 1)

        # Puis mise à jour régulière
        self.run_every(self.update_cumulus, "now", self.update_interval)

    # ------------------------------------------------------------------
    # Helpers lecture d'état
    # ------------------------------------------------------------------

    def _get_float(self, entity_id):
        """Retourne un float ou None si unavailable/unknown/erreur."""
        value = self.get_state(entity_id)
        if value in (None, "unknown", "unavailable"):
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def _get_heures_depuis_dernier_chauffe(self):
        """Heures écoulées depuis la dernière chauffe, à partir d'un timestamp."""
        ts = self.get_state(self.entity_last_heat)
        if not ts or ts in ("unknown", "unavailable"):
            return None

        try:
            dt = self.convert_utc(ts)
        except Exception as e:
            self.log(
                f"[Cumulus5Couches] Impossible de convertir le timestamp "
                f"{self.entity_last_heat}='{ts}': {e}",
                level="WARNING",
            )
            return None

        now = self.get_now()
        delta_h = (now - dt).total_seconds() / 3600.0
        return max(0.0, delta_h)

    # ------------------------------------------------------------------
    # Calcul principal
    # ------------------------------------------------------------------

    def update_cumulus(self, kwargs):
        # Température bas ballon (sonde réelle)
        t_bas = self._get_float(self.entity_temp_bas)
        if t_bas is None:
            self.log(
                f"[Cumulus5Couches] Température bas indisponible : "
                f"{self.entity_temp_bas}",
                level="WARNING",
            )
            return

        # Heures depuis la dernière chauffe
        heures_depuis = self._get_heures_depuis_dernier_chauffe()
        if heures_depuis is None:
            # Fallback : on considère qu'on vient de chauffer
            heures_depuis = 0.0

        # Consigne de chauffe (PV) ; défaut 55 °C
        t_cible = self._get_float(self.entity_consigne)
        if t_cible is None or t_cible <= t_bas:
            t_cible = max(t_bas + 1.0, 55.0)

        # --- Constantes du modèle ---
        volume_total = 300.0   # L (ballon)
        n_couches = 5
        volume_couche = volume_total / n_couches  # 60 L par couche
        t_froide = 15.0        # °C eau froide
        t_douche = 40.0        # °C cible douche

        # --- Stratification : persistance et intensité ---
        # On réduit tau_mix pour que ~10 h après la chauffe le haut
        # soit plus proche de la mesure au robinet (~52 °C).
        tau_mix = 30.0         # h : mélange plus rapide qu'avant (45 -> 30)
        k_strat = 1.0          # pas d'amplification artificielle du gradient

        # s = exp(-heures_depuis / tau_mix) ∈ [0, 1]
        s = math.exp(-max(0.0, heures_depuis) / tau_mix)

        # Gradient max possible entre bas et haut, borné par la consigne
        grad_max = max(0.0, (t_cible - t_bas) * k_strat)

        # Gradient réellement utilisé (diminue avec le temps)
        delta_t = grad_max * s

        # Température haut ballon (toujours entre T_bas et T_cible)
        t_haut = max(min(t_bas + delta_t, t_cible), t_bas)

        # --- Températures des 5 couches (profil raisonnable) ---
        # Bas ~ sonde, haut ~ T_haut; entre les deux on interpole avec
        # un profil plus chaud vers le haut.
        t1 = t_bas
        t2 = t_bas + 0.25 * (t_haut - t_bas)
        t3 = t_bas + 0.55 * (t_haut - t_bas)
        t4 = t_bas + 0.80 * (t_haut - t_bas)
        t5 = t_haut

        couches = [t1, t2, t3, t4, t5]

        # Température moyenne
        t_moy = sum(couches) / len(couches)

        # Volume équivalent à 40 °C pour chaque couche
        litres_40_total = 0.0
        for t in couches:
            facteur = max(0.0, (t - t_froide) / (t_douche - t_froide))
            litres_40_total += volume_couche * facteur

        # Nombre de douches (40 L / douche)
        litres_par_douche = 40.0
        douches = litres_40_total / litres_par_douche if litres_par_douche > 0 else 0.0

        # Log debug (ASCII only pour éviter les problèmes d'encodage)
        self.log(
            "[Cumulus5Couches] T_bas=%.1f, T_haut=%.1f, T_moy=%.1f, "
            "L_40C=%.0f, douches=%.1f, heures_depuis=%.2f"
            % (t_bas, t_haut, t_moy, litres_40_total, douches, heures_depuis)
        )

        # ------------------------------------------------------------------
        # Publication des capteurs Home Assistant
        # ------------------------------------------------------------------

        # 1) Couches individuelles
        for idx, temp in enumerate(couches, start=1):
            self.set_state(
                f"sensor.cumulus_v3_temp_couche_{idx}_c",
                state=round(temp, 1),
                attributes={
                    "friendly_name": f"Cumulus V3 - Temp couche {idx}",
                    "unit_of_measurement": "°C",
                    "layer_index": idx,
                    "model": "5_couches",
                },
            )

        # 2) Température moyenne
        self.set_state(
            "sensor.cumulus_v3_temp_moyenne_5c_c",
            state=round(t_moy, 1),
            attributes={
                "friendly_name": "Cumulus V3 - Temp moyenne (5 couches)",
                "unit_of_measurement": "°C",
                "model": "5_couches",
            },
        )

        # 3) Litres équivalents à 40 °C
        self.set_state(
            "sensor.cumulus_v3_litres_40c_equivalents_5c",
            state=round(litres_40_total, 0),
            attributes={
                "friendly_name": "Cumulus V3 - Litres équivalents 40°C (5 couches)",
                "unit_of_measurement": "L",
                "model": "5_couches",
            },
        )

        # 4) Douches disponibles
        self.set_state(
            "sensor.cumulus_v3_douches_disponibles_5c",
            state=round(douches, 1),
            attributes={
                "friendly_name": "Cumulus V3 - Douches disponibles (5 couches)",
                "unit_of_measurement": "douches",
                "litres_par_douche": litres_par_douche,
                "model": "5_couches",
            },
        )
