## Rigid body ball that players can push. The host simulates it and replicates the result.
class_name Ball
extends RigidBody3D


# PUBLIC METHODS

func push(impulse: Vector3) -> void:
    # Only the host simulates the ball, other peers just receive its state
    if not Fusion.is_master_client():
        return

    apply_central_impulse(impulse)
