import { Astal, Gdk, Gtk } from "ags/gtk4";
import app from "ags/gtk4/app";
import { Accessor, createState } from "ags";
import { hide_all_windows } from "@/windows";
import Graphene from "gi://Graphene?version=1.0";
import Adw from "gi://Adw?version=1";
import { config, theme } from "@/options";
const { margin } = theme.window;

type PopupProps = JSX.IntrinsicElements["window"] & {
   children?: any;
   width?: number;
   height?: number;
   margin_top?: number;
   margin_bottom?: number;
   margin_start?: number;
   margin_end?: number;
   gdkmonitor?: Gdk.Monitor;
   transitionType?: Gtk.RevealerTransitionType;
   transitionDuration?: number;
};

export function Popup({
   children,
   name,
   width,
   height,
   margin_top = margin.get(),
   margin_bottom = margin.get(),
   margin_start = margin.get(),
   margin_end = margin.get(),
   gdkmonitor,
   transitionType = Gtk.RevealerTransitionType.SLIDE_DOWN,
   transitionDuration = config.transition.get(),
   halign = Gtk.Align.CENTER,
   valign = Gtk.Align.CENTER,
   ...props
}: PopupProps) {
   const { TOP, BOTTOM, RIGHT, LEFT } = Astal.WindowAnchor;
   let contentbox: Adw.Clamp;
   const [visible, setVisible] = createState(false);
   const [revealed, setRevealed] = createState(false);

   function show() {
      setVisible(true);
      setRevealed(true);
   }
   function hide() {
      setRevealed(false);
   }

   function init(self: Gtk.Window) {
      // override existing show and hide methods
      Object.assign(self, { show, hide });
   }

   return (
      <window
         {...props}
         visible={visible}
         name={name}
         namespace={name}
         keymode={Astal.Keymode.ON_DEMAND}
         layer={Astal.Layer.OVERLAY}
         gdkmonitor={gdkmonitor}
         anchor={TOP | BOTTOM | RIGHT | LEFT}
         application={app}
         $={init}
         onNotifyVisible={({ visible }) => {
            if (visible) contentbox.grab_focus();
         }}
      >
         <Gtk.EventControllerKey
            onKeyPressed={({ widget }, keyval: number) => {
               if (keyval === Gdk.KEY_Escape) {
                  widget.hide();
               }
            }}
         />
         <Gtk.GestureClick
            onPressed={({ widget }, _, x, y) => {
               const [, rect] = children.compute_bounds(widget);
               const position = new Graphene.Point({ x, y });
               console.log(rect.get_width(), rect.get_height());

               if (!rect.contains_point(position)) {
                  hide_all_windows();
               }
            }}
         />
         <revealer
            transitionType={transitionType}
            transitionDuration={transitionDuration * 1000}
            revealChild={revealed}
            halign={halign}
            valign={valign}
            onNotifyChildRevealed={({ childRevealed }) =>
               setVisible(childRevealed)
            }
         >
            <Adw.Clamp
               $={(self) => (contentbox = self)}
               focusable
               maximum_size={width}
               heightRequest={height}
               margin_top={margin_top}
               margin_bottom={margin_bottom}
               margin_start={margin_start}
               margin_end={margin_end}
            >
               <box class={"main"}>{children}</box>
            </Adw.Clamp>
         </revealer>
      </window>
   );
}
