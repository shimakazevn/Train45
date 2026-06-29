extends HBoxContainer
## 티켓 컨테이너 애니메이션을 관리하는 [code]HBoxContainer[/code].
## 티켓 UI의 진입/퇴장 애니메이션을 제어한다.

## 티켓 컨테이너 애니메이션 플레이어 참조
@onready var ticket_container_anim = $TicketContainerAnim

## 티켓 진입 애니메이션을 재생한다. [code]RESET[/code] 애니메이션을 실행한다.
func ticket_in():
	ticket_container_anim.play("RESET")
	
## 티켓 퇴장 애니메이션을 재생한다. [code]out[/code] 애니메이션을 실행한다.
func ticket_out():
	ticket_container_anim.play("out")
