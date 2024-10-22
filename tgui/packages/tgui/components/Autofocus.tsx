import { Component, createRef } from "inferno";
import { InfernoPropsWithChildren } from "../misc";

/** Used to force the window to steal focus on load. Children optional */
export class Autofocus extends Component<InfernoPropsWithChildren> {
  ref = createRef<HTMLDivElement>();

  componentDidMount() {
    setTimeout(() => {
      this.ref.current?.focus();
    }, 1);
  }

  render() {
    return (
      <div ref={this.ref} tabIndex={-1}>
        {this.props.children}
      </div>
    );
  }
}
