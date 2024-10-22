import { InfernoNode } from "inferno";

// misc react-like types
export type InfernoReactNode = InfernoNode | InfernoReactNodeArray | undefined; // yes, the only thing missing from InfernoNode is undefined.
interface InfernoReactNodeArray extends Array<InfernoReactNode> {}
export type InfernoPropsWithChildren<P = unknown> = P & { children?: InfernoReactNode | undefined };
