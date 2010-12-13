using UnityEngine;
using System.Collections;

[RequireComponent(typeof(CharacterController))]
public class fpsWalker : MonoBehaviour
{
    public float speed = 6.0f;
    public float jumpSpeed = 8.0f;
    public float gravity = 20.0f;
    public float groundLevel = -1.0f;
    private Vector3 moveDirection = Vector3.zero;
    private bool grounded = false;

    void FixedUpdate()
    {
        if (grounded)
        {
            // We are grounded, so recalculate movedirection directly from axes
            moveDirection = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
            moveDirection = transform.TransformDirection(moveDirection);
            if (Input.GetKey(KeyCode.LeftShift) && (!Input.GetButton("Jump")))
            {
                moveDirection *= speed * 10;
                moveDirection.y = 0;
            }
            else
                moveDirection *= speed;

            if (Input.GetButton("Jump"))
            {
                moveDirection.y = jumpSpeed;
            }
        }

 

        Ray ray = new Ray(transform.position, Vector3.down);
        Debug.DrawRay(transform.position, Vector3.down*10);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit, 100f))
        {
            moveDirection.y -= gravity * Time.deltaTime;
            //grounded = (flags & CollisionFlags.CollidedBelow) != 0;
        }
        grounded = true;

        // Apply gravity
        CharacterController controller = GetComponent<CharacterController>();
        CollisionFlags flags = controller.Move(moveDirection * Time.deltaTime);


    }
}



